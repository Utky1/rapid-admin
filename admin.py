#!/usr/bin/env python3
import os
import requests
import json


def load_config():
    default_path = "/etc/rpdk1/config.json"
    local_path = os.path.join(os.path.dirname(__file__), "config.json")

    if os.path.exists(default_path):
        config_path = default_path
    elif os.path.exists(local_path):
        config_path = local_path
    else:
        raise FileNotFoundError(
            "No config.json found in /etc/rpdk1 or local directory.")

    with open(config_path, "r") as f:
        config = json.load(f)
        return config[0] if isinstance(config, list) else config


config = load_config()
__version__ = "1.0.0"

api_admin_url = config['API_ADMIN_URL']
ADMIN_USER = config['ADMIN_USER']
ADMIN_PASS = config['ADMIN_PASS']

LOGO = r"""
__________    _____ __________.___________     ____  __.____ 
\______   \  /  _  \\______   \   \______ \   |    |/ _/_   |
 |       _/ /  /_\  \|     ___/   ||    |  \  |      <  |   |
 |    |   \/    |    \    |   |   ||    `   \ |    |  \ |   |
 |____|_  /\____|__  /____|   |___/_______  / |____|__ \|___|
        \/         \/                     \/          \/     
"""


def show_banner():
    print(LOGO)
    print(f"Rapid K1 Console Tool  |  Version {__version__}\n")


def clear():
    os.system('cls' if os.name == 'nt' else 'clear')


def get_admin_data():
    dataid = input("Enter Data ID (leave blank for all data): ").strip()
    url = f"{api_admin_url}/{dataid}" if dataid else api_admin_url
    auth = (ADMIN_USER, ADMIN_PASS)
    response = requests.get(url, auth=auth)
    if response.status_code == 200:
        return response.json()
    return {"error": "Failed to retrieve data", "status_code": response.status_code}


def save_to_json_file(data, filename):
    if not filename.endswith('.json'):
        filename += '.json'

    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"Error saving file: {e}")
        return False


def get_data():
    clear()
    admin_data = get_admin_data()

    print("Received Data:")
    print(json.dumps(admin_data, indent=2))

    save_file = input(
        "\nDo you want to save this data to a JSON file? (y/n): ").lower()
    if save_file == 'y':
        filename = input("Enter filename (will add .json if not provided): ")
        if save_to_json_file(admin_data, filename):
            print(f"Data successfully saved to {filename}")
        else:
            print("Failed to save data to file")


def delete_data():
    clear()
    dataid = input("Enter Data ID (leave blank for all data): ").strip()

    if not dataid:
        confirm = input(
            "You are about to delete ALL admin data. This action cannot be undone. Are you sure? (y/n): ").lower()
        if confirm != 'y':
            print("Deletion cancelled.")
            return

    url = f"{api_admin_url}/{dataid}" if dataid else api_admin_url
    auth = (ADMIN_USER, ADMIN_PASS)
    response = requests.delete(url, auth=auth)
    if response.status_code == 204:
        print("Admin data successfully deleted.")
    else:
        print(
            f"Failed to delete admin data. Status code: {response.status_code}")


if __name__ == "__main__":
    clear()
    show_banner()
    option = input(
        "Choose an option:\n1. Get Admin Data\n2. Delete Admin Data (DANGEROUS)\nEnter 1 or 2: ")

    match option:
        case '1':
            get_data()
        case '2':
            delete_data()
        case _:
            print("Invalid option selected.")
