#Import Flask
from flask import Flask, jsonify, request, abort

#Import SQLAlchemy and Marshmallow
from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow

#Import CORS
from flask_cors import CORS

#Import MSQL Connector
import mysqlx

#Import Date and Time
import datetime
import time

#Import Secrets
import secrets

#Setup the app with Flask
app = Flask(__name__)

#Set the app with CORS
CORS(app)

#Config the connector
#app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+mysqlconnector://root:example@localhost:3306/test'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'

#Config the database tracking modifications
app.config['SQLALCHEMY_DATABASE_TRACK_MODIFICATIONS'] = False

#Config the tracking modifications
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

#SQLAlchemy Database Connection
db = SQLAlchemy(app)

#Marshmallow Data Types
ma = Marshmallow(app)

#User Data Structure Class
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.Text())
    first_name = db.Column(db.Text())
    last_name = db.Column(db.Text())
    username = db.Column(db.Text())
    password = db.Column(db.Text())
    is_admin = db.Column(db.Boolean(), default = False)
    creation_datetime = db.Column(db.DateTime, default = datetime.datetime.now)

    def __init__(self, email, first_name, last_name, username, password, is_admin):
        self.email = email
        self.first_name = first_name
        self.last_name = last_name
        self.username = username
        self.password = password
        self.is_admin = is_admin

#User Schema
class UserSchema(ma.Schema):
    class Meta:
        fields = ('id', 'email', 'first_name', 'last_name', 'username', 'password', 'is_admin', 'creation_datetime')

user_schema = UserSchema()
users_schema = UserSchema(many=True)

#Session Data Structure Class
class Session(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.Text())
    apikey = db.Column(db.Text())
    creation_datetime = db.Column(db.DateTime, default = datetime.datetime.now)

    def __init__(self, username, apikey):
        self.username = username
        self.apikey = apikey

#Session Schema
class SessionSchema(ma.Schema):
    class Meta:
        fields = ('id', 'username', 'apikey', 'creation_datetime')

session_schema = SessionSchema()
sessions_schema = SessionSchema(many=True)

#Connect to the db
with app.app_context():
    while True:
        try:
            db.create_all()
            break
        except Exception as e:
            print('Error while connecting to db')
            print(str(e))
            time.sleep(15)

#Get all users
@app.route('/get/all/users', methods = ['GET'])
def get_all_users():
    all_users = User.query.all()
    results = users_schema.dump(all_users)
    return jsonify(results)

#Get a user by username
@app.route('/get/user/<requested_username>', methods = ['GET'])
def get_user(requested_username):
    try:
        user = User.query.filter_by(username=requested_username).first()
        if user == None:
            raise
    except:
        abort(404)
    return user_schema.jsonify(user)

#Add a user if the username is available
@app.route('/add/user', methods = ['POST'])
def add_user():
    form_email = request.json['email']
    form_first_name = request.json['first_name']
    form_last_name = request.json['last_name']
    form_username = request.json['username']
    form_password = request.json['password']
    form_is_admin = request.json['is_admin']

    try:
        user = User.query.filter_by(username=form_username).first()
        if user != None:
            raise
    except:
        abort(409)

    user = User(form_email, form_first_name, form_last_name, form_username, form_password, form_is_admin)
    db.session.add(user)
    db.session.commit()
    return user_schema.jsonify(user)

#Update a user by username
@app.route('/update/user/<requested_username>', methods = ['PUT'])
def update_user(requested_username):
    try:
        user = User.query.filter_by(username=requested_username).first()
        if user == None:
            raise
    except:
        abort(404)

    form_email = request.json['email']
    form_first_name = request.json['first_name']
    form_last_name = request.json['last_name']
    form_username = request.json['username']
    form_password = request.json['password']
    form_is_admin = request.json['is_admin']

    user.email = form_email
    user.first_name = form_first_name
    user.last_name = form_last_name
    user.username = form_username
    user.password = form_password
    user.is_admin = form_is_admin

    db.session.commit()
    return user_schema.jsonify(user)

#Delete a user by username
@app.route('/delete/user/<requested_username>', methods = ['DELETE'])
def delete_user(requested_username):
    try:
        user = User.query.filter_by(username=requested_username).first()
        if user == None:
            raise
    except:
        abort(404)

    db.session.delete(user)
    db.session.commit()
    return user_schema.jsonify(user)

#Login and get a new API key
@app.route('/login', methods = ['POST'])
def login():
    form_username = request.json['username']
    form_password = request.json['password']

    try:
        user = User.query.filter_by(username=form_username).first()
        if user == None:
            raise
    except:
        abort(404)

    try:
        if user.username != form_username or user.password != form_password:
            raise
    except:
        abort(401)

    session = Session.query.filter_by(username=user.username).first()
    if session != None:
        db.session.delete(session)
        db.session.commit()

    session = Session(user.username, secrets.token_hex(16))
    db.session.add(session)

    db.session.commit()
    return session_schema.jsonify(session)

#Get all sessions
@app.route('/get/all/sessions', methods = ['GET'])
def get_all_sessions():
    all_sessions = Session.query.all()
    results = sessions_schema.dump(all_sessions)
    return jsonify(results)

#Health check
@app.route('/', methods = ['GET'])
def onlinecheck():
    return 'Okay'

#Run the app
if __name__ == "__main__":
    while True:
        try:
            app.run
            break
        except Exception as e:
            print('Error while running')
            print(str(e))
            time.sleep(15)