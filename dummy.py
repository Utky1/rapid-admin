import requests
import os

url = "https://rapid-k1.onrender.com/data/"
data = [{
    "name": "TEST0128",
    "os": "Windows 10",
    "ip": "10.4.2.1"
},
    {
    "name": "TEST0228",
    "os": "Ubuntu 20.04",
    "ip": "192.167.4.2"},
    {
    "name": "TEST0328",
    "os": "macOS Monterey",
    "ip": "172.243.1.2"},
    {
    "name": "TEST0428",
    "os": "Fedora 34",
    "ip": "213.1.5.3"
}, {
    "name": "TEST0528",
    "os": "Windows 11",
    "ip": "167.2.5.12"
}]

os.system('cls' if os.name == 'nt' else 'clear')

for entry in data:
    response = requests.post(url, json=entry)
    if response.status_code == 201:
        print(f"Data added successfully: {entry}")
    else:
        print(
            f"Failed to add data: {entry}, Status Code: {response.status_code}")
