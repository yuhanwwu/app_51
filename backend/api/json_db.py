import json, os
from datetime import datetime
from django.conf import settings

DATA_PATH = os.path.join(settings.BASE_DIR, 'data.json')

def _read_data():
    with open(DATA_PATH, 'r') as f:
        return json.load(f)

def _write_data(data):
    with open(DATA_PATH, 'w') as f:
        json.dump(data, f, indent=2, default=str)

# === CRUD functions ===

def get_users():
    return _read_data().get("users", [])

def get_repeat_tasks():
    return _read_data().get("repeat_tasks", [])

def get_one_off_tasks():
    return _read_data().get("one_off_tasks", [])

def add_user(user):
    data = _read_data()
    data["users"].append(user)
    _write_data(data)
    return user

def add_repeat_task(task):
    data = _read_data()
    task["id"] = max([t["id"] for t in data["repeat_tasks"]] + [0]) + 1
    data["repeat_tasks"].append(task)
    _write_data(data)
    return task

def add_one_off_task(task):
    data = _read_data()
    task["id"] = max([t["id"] for t in data["one_off_tasks"]] + [0]) + 1
    task["setdate"] = datetime.utcnow().isoformat() + "Z"
    data["one_off_tasks"].append(task)
    _write_data(data)
    return task

def mark_repeat_task_done(task_id, user_id):
    data = _read_data()
    for task in data["repeat_tasks"]:
        if task["id"] == task_id:
            task["lastdoneon"] = datetime.utcnow().isoformat() + "Z"
            task["lastdoneby"] = user_id
    _write_data(data)
