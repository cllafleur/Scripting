
from flask import Flask

app = Flask(__name__)

@app.route('/')

def index():
    return 'Hello, World !'

if __name__ == '__main__':
    app.run(debug=True)




class super:
    key = None
    name = "beautiful name"

    def __init__(self, key):
        self.key = key

#    def __init__(self, key, name):
#        self.key = key
#        self.name = name



def main():
    return None

s = super(2)
print(main())
print(s.name)


