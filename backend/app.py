import json
import os
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
app.debug = True

# Allow requests from GitHub Pages
CORS(app, 
     origins="*",
     methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
     allow_headers=['Content-Type', 'Authorization'])

# Add this after your CORS configuration:
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

print("Flask app starting...")
print("Debug mode:", app.debug)

# Database file path
DB_FILE = 'database.json'

def load_database():
    if os.path.exists(DB_FILE):
        with open(DB_FILE, 'r') as f:
            return json.load(f)
    return {
        "users": [],
        "repeat_tasks": [],
        "oneoff_tasks": []
    }

def save_database(data):
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=2, default=str)

@app.route('/api/users/', methods=['GET'])
def get_users():
    print("=== GET /api/users/ ===")
    db = load_database()
    print(f"Found {len(db['users'])} users")
    response = jsonify(db['users'])
    print("Response sent")
    return response

@app.route('/api/users/<username>/', methods=['GET'])
def get_user(username):
    print(f"=== GET /api/users/{username}/ ===")
    db = load_database()
    user = next((u for u in db['users'] if u['username'] == username), None)
    if user:
        print(f"User found: {user}")
        user_copy = user.copy()
        user_copy['assigned_repeat_tasks'] = [
            t for t in db['repeat_tasks'] if t.get('assignedto') == username
        ]
        user_copy['assigned_oneoff_tasks'] = [
            t for t in db['oneoff_tasks'] if t.get('assignedto') == username
        ]
        print(f"Returning user data: {user_copy}")
        return jsonify(user_copy)
    else:
        print(f"User '{username}' not found")
        return jsonify({"error": "User not found"}), 404

@app.route('/api/users/', methods=['POST'])
def create_user():
    print("=== POST /api/users/ ===")
    db = load_database()
    data = request.json
    print(f"Creating user: {data}")
    
    if any(u['username'] == data['username'] for u in db['users']):
        return jsonify({"error": "User already exists"}), 400
    
    user = {
        "username": data['username'],
        "name": data['name']
    }
    db['users'].append(user)
    save_database(db)
    print(f"User created: {user}")
    return jsonify(user), 201

@app.route('/api/repeat-tasks/', methods=['GET', 'POST'])
def repeat_tasks():
    print(f"=== {request.method} /api/repeat-tasks/ ===")
    db = load_database()
    if request.method == 'GET':
        return jsonify(db['repeat_tasks'])
    
    if request.method == 'POST':
        task = request.json
        task['id'] = len(db['repeat_tasks']) + 1
        task['lastdoneon'] = None
        task['lastdoneby'] = None
        db['repeat_tasks'].append(task)
        save_database(db)
        return jsonify(task), 201

@app.route('/api/oneoff-tasks/', methods=['GET', 'POST'])
def oneoff_tasks():
    print(f"=== {request.method} /api/oneoff-tasks/ ===")
    db = load_database()
    if request.method == 'GET':
        return jsonify(db['oneoff_tasks'])
    
    if request.method == 'POST':
        task = request.json
        task['id'] = len(db['oneoff_tasks']) + 1
        task['setdate'] = datetime.now().isoformat()
        db['oneoff_tasks'].append(task)
        save_database(db)
        return jsonify(task), 201

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"Starting Flask app on port {port}")
    app.run(host='0.0.0.0', port=port, debug=True)