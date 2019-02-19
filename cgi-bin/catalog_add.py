#!/usr/bin/env python3

import mysql.connector
import cgi
import cgitb
from os import environ
from pathlib import Path
import re

PASSWORD = Path('password').read_text()


class BaseCGI(object):
    def __init__(self, template_path):
        cgitb.enable()
        self.connection = None
        self.headers = ["Content-Type: text/html"]
        self.html = Path('app.html').read_text()
        self.template = Path(template_path).read_text()
        self.results = {}
        self.error = None

        try:
            # parse the request -- todo (move generic logic here)

            # connect to database
            self.connection = mysql.connector.connect(user='root',
                                                      password=PASSWORD,
                                                      database='serious_oltp',
                                                      host='127.0.0.1')
            # do the work
            self._run()
        except mysql.connector.Error as error:
            self.error = "Error -- %s" % error
        finally:
            self.respond()
            self.connection.close()

    def _run(self):
        raise NotImplementedError

    def respond(self):
        for header in self.headers:
            print(header)
        print()  # blank line required, end of headers
        if not self.error:
            # replace placeholder in template with content
            for key in self.results:
                self.template = re.sub(r'\${' + key + '}', self.results[key], self.template)
            # replace placeholder in html with template
            result = self.html.replace('<!--${results}-->', self.template)
        else:
            result = self.html.replace('<!--${error}-->', "<strong>" + self.error + "</strong><br/><hr/>")
        print(result)

    def add_result(self, key, value):
        self.results[key] = value

    @staticmethod
    def get_cookies():
        if 'HTTP_COOKIE' in environ:
            return environ['HTTP_COOKIE'].split(';')
        else:
            return dict()

    def add_cookie_to_header(self, key, value):
        self.headers.append("Set-Cookie: %s=%s" % (key, value))

    def query_get_first(self, query):
        c = self.connection.cursor()
        c.execute(query)
        return c.fetchone()

    def query_get_all(self, query):
        c = self.connection.cursor()
        c.execute(query)
        return c.fetchall()

    def query_committed(self, query):
        c = self.connection.cursor()
        c.execute(query)
        self.connection.commit()

    @staticmethod
    def table_from_tuples(tuples_list):
        table_template = Path('./html-templates/table.html').read_text()

        # first tuple is the header
        header = tuples_list.pop(0)
        items = ''
        for item in header:
            items += '<th>' + item + '</th>'
        table_template = re.sub(r'\${head}', '<tr>' + items + '</tr>', table_template)

        # subsequent tuples are the data
        data_rows = ''
        for row in tuples_list:
            items = ''
            for item in row:
                items += '<td>' + str(item) + '</td>'
            data_rows += '<tr>' + items + '</tr>'

        table_template = re.sub(r'\${body}', data_rows, table_template)

        return table_template

    @staticmethod
    def table_from_list(data_list):
        table_template = Path('./html-templates/table.html').read_text()

        # first item is the header
        header = data_list.pop(0)
        table_template = re.sub(r'\${head}', '<tr><th>' + header + '</th></tr>', table_template)

        # subsequent items are the data
        data_rows = ''
        for row in data_list:
            items = ''
            data_rows += '<tr><td>' + str(row[0]) + '</td></tr>'  # fix -- hacky since query returns incomplete tuples

        table_template = re.sub(r'\${body}', data_rows, table_template)
        return table_template


class CatalogAdd(BaseCGI):
    q_catalog_exists = '''
        SELECT 1
        FROM catalog c
        JOIN item i ON c.item_id = i.id
        JOIN supplier s ON c.supplier_id = s.id
        WHERE i.name = '%s' AND s.name = '%s';
        '''

    q_catalog_add = '''
        INSERT INTO catalog (item_id, supplier_id, price, start) VALUES (
            (SELECT id FROM item WHERE name = '%s'),
            (SELECT id FROM supplier WHERE name = '%s'),
            ('%s'),
            ('%s')
        );
        '''

    # todo select only items that have not ended and have already started
    q_catalog = '''
        SELECT i.name, s.name, price, start
        FROM catalog c
        JOIN item i ON c.item_id = i.id
        JOIN supplier s ON c.supplier_id = s.id
        ORDER BY i.name, start, price, s.name;
        '''

    q_item_exists = '''
        SELECT 1
        FROM item
        WHERE name = '%s';
        '''

    q_supplier_exists = '''
        SELECT 1
        FROM supplier
        WHERE name = '%s';
        '''

    def __init__(self):
        super().__init__('./html-templates/catalog_add.html')

    def _run(self):
        form = cgi.FieldStorage()
        # todo + update price/allow discontinuing products
        # todo + automatically add item if it doesn't exist (can't do same for supplier, unless we prompt)

        # retrieve input values
        item = form["item"].value
        supplier = form["supplier"].value
        price = form["price"].value
        start = form["start"].value

        # item exists?
        if not self.query_get_first(self.q_item_exists % item):
            self.add_result('result', 'The item: %s needs to be added to items before continuing' % item)
        # supplier exists?
        elif not self.query_get_first(self.q_supplier_exists % supplier):
            self.add_result('result', 'The supplier: %s needs to be added to suppliers before continuing' % supplier)

        # catalog item exists?
        elif not self.query_get_first(self.q_catalog_exists % (item, supplier)):
            self.query_committed(self.q_catalog_add % (item, supplier, price, start))
            self.add_result('result', 'Added Catalog item: %s at %s' % (item, supplier))
        else:
            self.add_result('result', '%s at %s is already in the Catalog' % (item, supplier))

        updated_items = [('item', 'supplier', 'price', 'start')]
        updated_items.extend(self.query_get_all(self.q_catalog))
        table = self.table_from_tuples(updated_items)
        self.add_result('table', table)


CatalogAdd()
