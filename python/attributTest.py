
import os

def multiply(old_function):
	def new_function(*args,**options):
		return (old_function(*args, **options)+ '\n') *2
	return new_function

@multiply
def getText():
	return "Hello world" " !"

def super():
	return 'cool !'

print( getText())

for filename in os.listdir('.'):
	print(filename)

