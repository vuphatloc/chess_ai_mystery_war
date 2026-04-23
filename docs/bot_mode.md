Để AI Agent có thể lập trình được hệ thống Bot có độ khó thực tế theo các bậc Elo, chúng ta cần chuyển đổi các con số Elo thành các **tham số thuật toán** (Parameters).

Trong cờ vua, Bot thường chạy trên thuật toán **Minimax** với cắt tỉa **Alpha-Beta**. Chúng ta sẽ điều khiển 3 yếu tố chính để giả lập Elo: **Độ sâu (Depth)**, **Độ nhiễu (Randomness/Error Rate)**, và **Hàm đánh giá (Evaluation Function)**.

Dưới đây là bảng mô tả kỹ thuật để bạn đưa vào file AI\_BOT\_SPECS.md hoặc gửi cho DeepSeek:

🤖 Đặc tả kỹ thuật Bot AI theo cấp độ Elo
-----------------------------------------

### 1\. Cơ chế cốt lõi (Core Engine)

AI sẽ sử dụng thuật toán **Minimax** kết hợp với **DeepSeek Reasoner API** cho các nước đi quan trọng. Để giả lập lỗi của con người ở Elo thấp, chúng ta áp dụng công thức:

> Final\_Move = (Random\_Probability < Error\_Rate) ? Random\_Legal\_Move : Best\_Move\_From\_Engine

### 2\. Bảng tham số chi tiết theo Elo

**Elo RangeRankMax DepthError RateĐặc điểm lối chơi (AI Behavior)400 - 600Beginner**1 - 240%Thường xuyên bỏ sót việc quân mình bị ăn. Di chuyển quân ngẫu nhiên, không có mục đích chiếm trung tâm.**600 - 900Novice**225%Bắt đầu biết ăn quân đối phương nếu lộ ra, nhưng chưa biết nhìn xa các nước chiếu. Hay mắc lỗi "Blunder".**900 - 1200Intermediate**315%Biết bảo vệ quân, biết nhập thành. Có kiến thức cơ bản về khai cuộc nhưng hay thua ở tàn cuộc.**1200 - 1500Advanced**48%Đánh chắc chắn, biết phối hợp các quân (Song xe, Xe pháo). Bắt đầu biết tận dụng sai lầm nhỏ của đối thủ.**1500 - 1800Expert**5 - 63%Tính toán được các chuỗi đổi quân có lợi. Hiểu về cấu trúc Tốt (Pawn structure) và kiểm soát không gian.**1800 - 2100Master**81%Rất ít mắc lỗi ngớ ngẩn. Có khả năng đọc hiểu ý đồ chiến thuật phức tạp và bẫy đối phương.**2100 - 2500Grandmaster**12+0%Sử dụng DeepSeek R1 để tính toán. Đánh gần như hoàn hảo. Tối ưu hóa mọi lợi thế nhỏ nhất.

### 3\. Logic đặc thù cho các biến thể "Mystery War"

Khi làm Bot cho Cờ Úp (Hidden Identity) và Sương mù (Fog of War), AI Agent cần implement thêm các logic sau:

#### A. Đối với Hidden Identity (Cờ Úp):

*   **Beginner - Novice:** Bot coi quân úp là quân "Vô danh", chỉ di chuyển dựa trên luật của ô đang đứng.
    
*   **Expert - Grandmaster:** Bot có khả năng **"Xác suất hóa"**. Nó sẽ tính toán: _"Dựa trên các quân đã lộ diện, ô này có 12% là Hậu, 8% là Xe"_. Nó sẽ chơi mạo hiểm hoặc an toàn dựa trên bảng xác suất này.
    

#### B. Đối với Fog of War (Sương mù):

*   **Elo thấp:** Bot chỉ tính toán dựa trên những gì nó thấy. Nếu quân địch khuất trong sương mù, nó coi như quân đó không tồn tại.
    
*   **Elo cao:** Bot sử dụng **"Heuristic Memory"**. Nó ghi nhớ vị trí cuối cùng nhìn thấy quân đối phương và dự đoán các hướng di chuyển có thể có của đối thủ trong vùng tối (Probabilistic Heatmap).
    

### 4\. Hướng dẫn AI Agent implement code (Prompt mẫu)

> _"Hãy viết một class BotService trong Flutter. Class này nhận vào difficultyLevel (Elo). Sử dụng thuật toán Minimax. Nếu Elo < 1200, hãy giới hạn searchDepth xuống 2 và thêm hàm applyHumanError() để thỉnh thoảng chọn một nước đi ngẫu nhiên thay vì nước đi tốt nhất. Nếu Elo > 2100, hãy tích hợp gọi DeepSeek-Reasoner để đưa ra nước đi tối ưu nhất."_

### 💡 Lưu ý về trải nghiệm người dùng (UX):

Để tăng tính thực tế, bạn nên yêu cầu AI thêm một khoảng **"Think Time"** (Thời gian suy nghĩ giả lập):

*   **Beginner:** Đi rất nhanh (1-2 giây) nhưng hay sai.
    
*   **Expert:** Suy nghĩ lâu hơn (5-10 giây) ở các tình huống phức tạp để tạo cảm giác giống đang đấu với người thật