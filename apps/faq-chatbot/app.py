"""FAQ/검색형 챗봇 목업 — 보안 취약점 실습용.

의도적으로 취약하게 설계된 목업 애플리케이션입니다.
실제 서비스에 절대 사용하지 마십시오.
"""

import json
import os
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

FAQ_DATA = [
    {
        "id": 1,
        "category": "계좌",
        "question": "계좌 잔액을 확인하고 싶어요",
        "answer": "모바일 앱 > 자산관리 > 계좌조회에서 확인할 수 있습니다.",
        "keywords": ["계좌", "잔액", "조회"],
    },
    {
        "id": 2,
        "category": "이체",
        "question": "이체 한도를 변경하고 싶어요",
        "answer": "모바일 앱 > 설정 > 이체한도 변경에서 1일 최대 5억원까지 설정 가능합니다. 본인인증이 필요합니다.",
        "keywords": ["이체", "한도", "변경"],
    },
    {
        "id": 3,
        "category": "카드",
        "question": "카드 분실 신고는 어떻게 하나요?",
        "answer": "고객센터(1588-0000) 또는 모바일 앱 > 카드관리 > 분실신고에서 가능합니다. 24시간 접수 가능합니다.",
        "keywords": ["카드", "분실", "신고"],
    },
    {
        "id": 4,
        "category": "대출",
        "question": "대출 금리를 확인하고 싶어요",
        "answer": "현재 신용대출 기준금리 3.5%~7.2%입니다. 개인 신용등급에 따라 차등 적용됩니다.",
        "keywords": ["대출", "금리", "이자"],
    },
    {
        "id": 5,
        "category": "보안",
        "question": "OTP 등록은 어떻게 하나요?",
        "answer": "영업점 방문 또는 모바일 앱 > 보안설정 > OTP 등록에서 가능합니다.",
        "keywords": ["OTP", "등록", "보안"],
    },
]

ADMIN_DATA = {
    "admin_password": "admin2024!@#",
    "db_connection": "postgresql://admin:dbpass@10.0.1.5:5432/banking",
    "api_key": "sk-internal-api-key-do-not-expose",
    "internal_note": "2024년 하반기 시스템 점검: 매주 화요일 02:00~04:00",
}

USERS = {
    "user001": {"name": "김보안", "account": "110-123-456789", "balance": 5230000},
    "user002": {"name": "이테스트", "account": "110-987-654321", "balance": 12500000},
    "user003": {"name": "박진단", "account": "110-555-333222", "balance": 890000},
}


def search_faq(query):
    query_lower = query.lower()
    results = []
    for faq in FAQ_DATA:
        score = 0
        for kw in faq["keywords"]:
            if kw in query_lower:
                score += 1
        if score > 0 or query_lower in faq["question"].lower():
            results.append({**faq, "score": score})
    results.sort(key=lambda x: x["score"], reverse=True)
    return results[:3]


@app.route("/")
def index():
    return render_template_string(FAQ_HTML)


@app.route("/api/search", methods=["POST"])
def api_search():
    data = request.get_json() or {}
    query = data.get("query", "")
    if not query:
        return jsonify({"error": "query is required"}), 400

    results = search_faq(query)
    if results:
        return jsonify({"results": results, "count": len(results)})
    return jsonify({"results": [], "count": 0, "message": "관련 FAQ를 찾을 수 없습니다."})


@app.route("/api/user/<user_id>", methods=["GET"])
def get_user(user_id):
    """취약점: 인증 없이 사용자 정보 조회 가능 (IDOR)"""
    user = USERS.get(user_id)
    if user:
        return jsonify(user)
    return jsonify({"error": "User not found"}), 404


@app.route("/api/admin/config", methods=["GET"])
def get_admin_config():
    """취약점: 인증 없이 관리자 설정 조회 가능"""
    return jsonify(ADMIN_DATA)


@app.route("/api/faq/<int:faq_id>", methods=["GET"])
def get_faq(faq_id):
    faq = next((f for f in FAQ_DATA if f["id"] == faq_id), None)
    if faq:
        return jsonify(faq)
    return jsonify({"error": "FAQ not found"}), 404


@app.route("/api/render", methods=["POST"])
def render_response():
    """취약점: 사용자 입력이 HTML에 직접 삽입 (XSS)"""
    data = request.get_json() or {}
    content = data.get("content", "")
    html = f"<div class='response'>{content}</div>"
    return jsonify({"html": html})


@app.route("/health")
def health():
    return {"status": "ok"}


FAQ_HTML = """<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>금융 FAQ 챗봇</title>
    <style>
        :root { --bg: #0f1117; --surface: #1a1d27; --border: #2a2e3b; --text: #e4e4e7; --muted: #9ca3af; --accent: #6366f1; }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); height: 100vh; display: flex; flex-direction: column; }
        .header { padding: 16px 24px; border-bottom: 1px solid var(--border); }
        .header h1 { font-size: 18px; }
        .header p { font-size: 13px; color: var(--muted); }
        .chat { flex:1; overflow-y:auto; padding: 24px; display:flex; flex-direction:column; gap:12px; }
        .msg { max-width: 70%; padding: 12px 16px; border-radius: 12px; font-size: 14px; line-height: 1.6; }
        .msg.bot { background: var(--surface); border: 1px solid var(--border); align-self: flex-start; }
        .msg.user { background: var(--accent); align-self: flex-end; }
        .input-area { padding: 16px 24px; border-top: 1px solid var(--border); display: flex; gap: 12px; }
        .input-area input { flex:1; padding: 12px 16px; background: var(--surface); border: 1px solid var(--border); border-radius: 8px; color: var(--text); font-size: 14px; outline:none; }
        .input-area input:focus { border-color: var(--accent); }
        .input-area button { padding: 12px 24px; background: var(--accent); border:none; border-radius: 8px; color:white; cursor:pointer; font-size: 14px; }
        .suggestions { display:flex; gap:8px; flex-wrap:wrap; margin-top: 8px; }
        .suggestion { padding: 6px 14px; background: var(--bg); border: 1px solid var(--border); border-radius: 20px; font-size: 12px; color: var(--muted); cursor:pointer; }
        .suggestion:hover { border-color: var(--accent); color: var(--text); }
        .hint-bar { padding: 8px 24px; border-top: 1px solid var(--border); }
        .hint-btn { background: #23262f; border: 1px solid var(--border); border-radius: 6px; padding: 4px 12px; font-size: 11px; color: var(--muted); cursor: pointer; }
        .hint-btn:hover { color: var(--text); border-color: #555; }
        .hint-text { font-size: 11px; color: var(--muted); margin-top: 6px; display: none; }
    </style>
</head>
<body>
    <div class="header">
        <h1>💬 금융 FAQ 챗봇</h1>
        <p>자주 묻는 질문을 검색해보세요</p>
    </div>
    <div class="chat" id="chat">
        <div class="msg bot">
            안녕하세요! 금융 FAQ 챗봇입니다. 궁금한 내용을 입력해주세요.
            <div class="suggestions">
                <span class="suggestion" onclick="sendMsg('계좌 잔액 조회')">계좌 잔액 조회</span>
                <span class="suggestion" onclick="sendMsg('이체 한도 변경')">이체 한도 변경</span>
                <span class="suggestion" onclick="sendMsg('카드 분실 신고')">카드 분실 신고</span>
            </div>
        </div>
    </div>
    <div class="hint-bar">
        <button class="hint-btn" onclick="var t=document.getElementById('hint');t.style.display=t.style.display==='block'?'none':'block'">Hint</button>
        <div class="hint-text" id="hint">실습 힌트: /api/admin/config, /api/user/user001 등의 엔드포인트를 직접 호출</div>
    </div>
    <div class="input-area">
        <input type="text" id="input" placeholder="질문을 입력하세요..." onkeydown="if(event.key==='Enter')send()">
        <button onclick="send()">전송</button>
    </div>
    <script>
        function addMsg(text, cls) {
            const d = document.createElement('div');
            d.className = 'msg ' + cls;
            d.innerHTML = text;
            document.getElementById('chat').appendChild(d);
            d.scrollIntoView({behavior:'smooth'});
        }
        function sendMsg(text) {
            document.getElementById('input').value = text;
            send();
        }
        async function send() {
            const input = document.getElementById('input');
            const q = input.value.trim();
            if (!q) return;
            addMsg(q, 'user');
            input.value = '';
            try {
                const res = await fetch('/api/search', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({query: q})
                });
                const data = await res.json();
                if (data.results && data.results.length > 0) {
                    let html = '';
                    data.results.forEach(r => {
                        html += '<b>' + r.question + '</b><br>' + r.answer + '<br><br>';
                    });
                    addMsg(html, 'bot');
                } else {
                    addMsg('죄송합니다. 관련 FAQ를 찾을 수 없습니다. 고객센터(1588-0000)로 문의해주세요.', 'bot');
                }
            } catch(e) {
                addMsg('오류가 발생했습니다: ' + e.message, 'bot');
            }
        }
    </script>
</body>
</html>"""

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=False)
