#!/bin/python


import simplejson as json
from flask import Flask, jsonify

app = Flask(__name__)

tasks = [
    {
        'id': 1,
        'title':u'Buy groceries',
        'description': u'Milk,Cheese, Pizza, Fruit',
        'done':False
    },
    {
        'id':2,
        'title':u'Learn Python',
        'description':u'Need to find a good Python tutorial',
        'done':False
    }
]

#encoded = jsonify({'tasks': tasks})
encoded = json.dumps({'tasks':tasks})

print(encoded)

