import os
import requests
from flask import Flask, request, jsonify
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# These should be set in your environment or .env file
AZURE_CLIENT_ID = os.getenv('AZURE_CLIENT_ID')
AZURE_CLIENT_SECRET = os.getenv('AZURE_CLIENT_SECRET')
AZURE_TENANT_ID = os.getenv('AZURE_TENANT_ID')
AZURE_ASSISTANT_ID = os.getenv('AZURE_ASSISTANT_ID')
AZURE_ENDPOINT = os.getenv('AZURE_ENDPOINT')  # e.g. https://nistbot-resource.services.ai.azure.com/api/projects/NISTBot
API_VERSION = '2025-05-01'

# Helper: Get Azure token using client credentials
def get_azure_token():
    url = f"https://login.microsoftonline.com/{AZURE_TENANT_ID}/oauth2/v2.0/token"
    data = {
        'grant_type': 'client_credentials',
        'client_id': AZURE_CLIENT_ID,
        'client_secret': AZURE_CLIENT_SECRET,
        'scope': 'https://ai.azure.com/.default'
    }
    resp = requests.post(url, data=data)
    resp.raise_for_status()
    return resp.json()['access_token']

# Proxy endpoint for your Flutter app
@app.route('/api/nistbot', methods=['POST'])
def nistbot_proxy():
    user_message = request.json.get('message')
    if not user_message:
        return jsonify({'error': 'Missing message'}), 400

    # 1. Get Azure token
    token = get_azure_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }

    # 2. Create thread
    thread_resp = requests.post(f"{AZURE_ENDPOINT}/threads?api-version={API_VERSION}", headers=headers, json={})
    thread_resp.raise_for_status()
    thread_id = thread_resp.json()['id']

    # 3. Add user message
    msg_payload = {'role': 'user', 'content': user_message}
    msg_resp = requests.post(f"{AZURE_ENDPOINT}/threads/{thread_id}/messages?api-version={API_VERSION}", headers=headers, json=msg_payload)
    msg_resp.raise_for_status()

    # 4. Run the thread
    run_payload = {'assistant_id': AZURE_ASSISTANT_ID}
    run_resp = requests.post(f"{AZURE_ENDPOINT}/threads/{thread_id}/runs?api-version={API_VERSION}", headers=headers, json=run_payload)
    run_resp.raise_for_status()
    run_id = run_resp.json()['id']

    # 5. Poll for completion
    for _ in range(15):
        import time; time.sleep(2)
        status_resp = requests.get(f"{AZURE_ENDPOINT}/threads/{thread_id}/runs/{run_id}?api-version={API_VERSION}", headers=headers)
        status_resp.raise_for_status()
        status = status_resp.json()['status']
        if status in ('completed', 'failed', 'cancelled'):
            break
    else:
        return jsonify({'error': 'Timed out waiting for agent response.'}), 504

    # 6. Get agent response
    messages_resp = requests.get(f"{AZURE_ENDPOINT}/threads/{thread_id}/messages?api-version={API_VERSION}", headers=headers)
    messages_resp.raise_for_status()
    data = messages_resp.json().get('data', [])
    bot_reply = 'No response from NISTBot.'
    assistant_msgs = [m for m in data if m.get('role') == 'assistant']
    if assistant_msgs:
        last_msg = assistant_msgs[-1]
        if isinstance(last_msg.get('content'), list):
            for block in last_msg['content']:
                if block.get('type') == 'text' and block.get('text', {}).get('value'):
                    bot_reply = block['text']['value']
                    break
    return jsonify({'reply': bot_reply})

if __name__ == '__main__':
    app.run(debug=True)
