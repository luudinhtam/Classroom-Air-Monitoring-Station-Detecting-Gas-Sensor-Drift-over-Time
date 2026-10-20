<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String chatbotCtx = request.getContextPath();
%>

<style>
    /* 1. Nút tròn mở Chatbot góc dưới bên phải */
    #chatbotToggleBtn {
        position: fixed;
        bottom: 24px;
        right: 24px;
        width: 58px;
        height: 58px;
        border-radius: 50%;
        background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #9333ea 100%);
        box-shadow: 0 8px 24px rgba(99, 102, 241, 0.45);
        color: #ffffff;
        border: none;
        cursor: pointer;
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 26px;
        transition: transform 0.25s ease, box-shadow 0.25s ease;
        outline: none;
    }
    #chatbotToggleBtn:hover {
        transform: scale(1.1);
        box-shadow: 0 10px 28px rgba(99, 102, 241, 0.6);
    }

    /* 2. Cửa sổ khung Chat (Khớp mẫu hình ảnh) */
    #chatbotWindow {
        position: fixed;
        bottom: 96px;
        right: 24px;
        width: 350px;
        height: 510px;
        max-height: calc(100vh - 120px);
        background: #ffffff;
        border-radius: 18px;
        box-shadow: 0 16px 40px rgba(0, 0, 0, 0.22);
        display: none;
        flex-direction: column;
        overflow: hidden;
        z-index: 9999;
        border: 1px solid rgba(226, 232, 240, 0.8);
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        animation: chatbotPopup 0.25s cubic-bezier(0.16, 1, 0.3, 1);
    }

    @keyframes chatbotPopup {
        from { opacity: 0; transform: translateY(16px) scale(0.96); }
        to { opacity: 1; transform: translateY(0) scale(1); }
    }

    /* Header thanh tiêu đề Gradient tím */
    .chatbot-header {
        background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #a855f7 100%);
        color: #ffffff;
        padding: 14px 18px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        user-select: none;
    }
    .chatbot-header-title {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 15px;
        font-weight: 700;
        letter-spacing: 0.2px;
    }
    .chatbot-header-close {
        background: none;
        border: none;
        color: #ffffff;
        font-size: 20px;
        cursor: pointer;
        opacity: 0.85;
        line-height: 1;
        padding: 0 4px;
        transition: opacity 0.2s ease;
    }
    .chatbot-header-close:hover { opacity: 1; }

    /* Vùng chứa tin nhắn */
    .chatbot-body {
        flex: 1;
        background: #f8fafc;
        padding: 16px;
        overflow-y: auto;
        display: flex;
        flex-direction: column;
        gap: 12px;
    }

    /* Bong bóng tin nhắn Bot */
    .chat-bubble-bot {
        align-self: flex-start;
        background: #ffffff;
        color: #1e293b;
        padding: 11px 15px;
        border-radius: 16px 16px 16px 4px;
        max-width: 85%;
        font-size: 13.5px;
        line-height: 1.5;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
        border: 1px solid #f1f5f9;
        word-break: break-word;
    }

    /* Bong bóng tin nhắn Người dùng (Màu tím khớp ảnh) */
    .chat-bubble-user {
        align-self: flex-end;
        background: linear-gradient(135deg, #6366f1, #8b5cf6);
        color: #ffffff;
        padding: 10px 16px;
        border-radius: 16px 16px 4px 16px;
        max-width: 80%;
        font-size: 13.5px;
        line-height: 1.5;
        box-shadow: 0 3px 10px rgba(99, 102, 241, 0.28);
        word-break: break-word;
    }

    /* Hiệu ứng Bot đang gõ */
    .chat-typing {
        align-self: flex-start;
        display: none;
        background: #ffffff;
        padding: 10px 16px;
        border-radius: 16px 16px 16px 4px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        gap: 5px;
        align-items: center;
    }
    .chat-typing-dot {
        width: 7px;
        height: 7px;
        border-radius: 50%;
        background: #8b5cf6;
        animation: chatBounce 1.4s infinite ease-in-out both;
    }
    .chat-typing-dot:nth-child(1) { animation-delay: -0.32s; }
    .chat-typing-dot:nth-child(2) { animation-delay: -0.16s; }
    @keyframes chatBounce {
        0%, 80%, 100% { transform: scale(0); }
        40% { transform: scale(1); }
    }

    /* Footer: Thanh gõ tin nhắn */
    .chatbot-footer {
        background: #ffffff;
        border-top: 1px solid #e2e8f0;
        padding: 10px 12px;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .chatbot-input {
        flex: 1;
        border: 1px solid #cbd5e1;
        border-radius: 24px;
        padding: 9px 16px;
        font-size: 13px;
        outline: none;
        transition: border-color 0.2s ease, box-shadow 0.2s ease;
        background: #ffffff;
        color: #0f172a;
    }
    .chatbot-input:focus {
        border-color: #6366f1;
        box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
    }
    .chatbot-send-btn {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: linear-gradient(135deg, #6366f1, #8b5cf6);
        color: #ffffff;
        border: none;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 15px;
        transition: transform 0.15s ease, opacity 0.15s ease;
        flex-shrink: 0;
        outline: none;
    }
    .chatbot-send-btn:hover {
        transform: scale(1.06);
    }
    .chatbot-send-btn:active {
        transform: scale(0.95);
    }
</style>

<button type="button" id="chatbotToggleBtn" title="" aria-label="Open chat">
    💬
</button>

<!-- Khung cửa sổ Chatbot -->
<div id="chatbotWindow">
    <div class="chatbot-header">
        <div class="chatbot-header-title">
            <span>🤖</span>
            <span>AI Assistant</span>
        </div>
        <button type="button" class="chatbot-header-close" id="chatbotCloseBtn" title="Close">&times;</button>
    </div>

    <div class="chatbot-body" id="chatbotMessages">
        <!-- Tin nhắn chào đầu tiên giống hình mẫu -->
        <div class="chat-bubble-bot">
            Hello! I'm Airroom AI Asssistant. How can I help you 😊
        </div>

        <div class="chat-typing" id="chatbotTyping">
            <div class="chat-typing-dot"></div>
            <div class="chat-typing-dot"></div>
            <div class="chat-typing-dot"></div>
        </div>
    </div>

    <div class="chatbot-footer">
        <input type="text" id="chatbotInput" class="chatbot-input" placeholder="Ask something..." autocomplete="off">
        <button type="button" id="chatbotSendBtn" class="chatbot-send-btn" title="Send message">
            ➤
        </button>
    </div>
</div>

<script>
    (function() {
        var toggleBtn = document.getElementById('chatbotToggleBtn');
        var chatWindow = document.getElementById('chatbotWindow');
        var closeBtn = document.getElementById('chatbotCloseBtn');
        var input = document.getElementById('chatbotInput');
        var sendBtn = document.getElementById('chatbotSendBtn');
        var messages = document.getElementById('chatbotMessages');
        var typing = document.getElementById('chatbotTyping');

        if (!toggleBtn || !chatWindow) return;

        // Bật/tắt cửa sổ chat
        toggleBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            if (chatWindow.style.display === 'flex') {
                chatWindow.style.display = 'none';
            } else {
                chatWindow.style.display = 'flex';
                setTimeout(function() { input.focus(); }, 150);
                scrollToBottom();
            }
        });

        closeBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            chatWindow.style.display = 'none';
        });

        // Gửi tin nhắn khi bấm nút Gửi hoặc ấn Enter
        sendBtn.addEventListener('click', sendMessage);
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                sendMessage();
            }
        });

        function scrollToBottom() {
            messages.scrollTop = messages.scrollHeight;
        }

        function appendMessage(text, isUser) {
            var bubble = document.createElement('div');
            bubble.className = isUser ? 'chat-bubble-user' : 'chat-bubble-bot';
            bubble.textContent = text;
            messages.insertBefore(bubble, typing);
            scrollToBottom();
        }

        function sendMessage() {
            var text = input.value.trim();
            if (!text) return;

            appendMessage(text, true);
            input.value = '';

            // Hiển thị trạng thái Bot đang gõ
            typing.style.display = 'flex';
            scrollToBottom();

            // Gửi tin nhắn về ChatbotServlet xử lý Google Gemini
            fetch('<%= chatbotCtx %>/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                },
                body: 'message=' + encodeURIComponent(text)
            })
            .then(function(res) {
                return res.json();
            })
            .then(function(data) {
                typing.style.display = 'none';
                if (data && data.reply) {
                    appendMessage(data.reply, false);
                } else {
                    appendMessage('Sorry, I am unable to answer this question at the moment. Please contact the administrator or try again later.', false);
                }
            })
            .catch(function(err) {
                typing.style.display = 'none';
                appendMessage('Sorry, I cannot answer this question at the moment. Please try again later..', false);
            });
        }
    })();
</script>
