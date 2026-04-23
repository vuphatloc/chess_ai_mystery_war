Chào bạn, để AI Agent có thể lập trình chính xác, chúng ta cần một bản mô tả logic cực kỳ chi tiết (Technical Logic) cho từng biến thể, đặc biệt là cách chúng tương tác với nhau.

Dưới đây là bản đặc tả kỹ thuật để bạn đưa vào file GAME\_RULES.md hoặc ném thẳng cho DeepSeek "vibe code":

1\. Hidden Identity (Cờ Úp - Trọng tâm)
---------------------------------------

Đây là cơ chế cốt lõi. AI cần xử lý sự sai lệch giữa "Hình dáng bên ngoài" và "Bản chất bên trong".

*   **Trạng thái quân cờ:** Có 2 thuộc tính loại quân: visualRole (vị trí đứng ban đầu) và actualRole (giá trị thật).
    
*   **Logic di chuyển:**
    
    *   If isRevealed == false: Quân cờ chỉ được phép đi theo luật của visualRole (ô nó đang đứng lúc bắt đầu).
        
    *   If isRevealed == true: Đi theo luật của actualRole.
        
*   **Sự kiện Lật quân (The Reveal Trigger):** Xảy ra ngay sau khi lệnh move hoàn tất.
    
    *   _Lưu ý cho AI:_ Phải cập nhật lại tập hợp các nước đi hợp lệ (validMoves) ngay sau khi lật vì tầm xa của quân cờ đã thay đổi.
        
*   **Ngoại lệ:** Quân Vua (King) luôn có isRevealed = true ngay từ đầu.
    

2\. Fog of War (Cờ Sương Mù)
----------------------------

Cơ chế này quản lý **"Tầm nhìn" (Visibility)** thay vì luật đi.

*   **Mảng Tầm nhìn (Vision Map):** Một mảng 8x8 kiểu Boolean.
    
*   **Tính toán Shadow:** \* Mỗi nước đi, AI phải duyệt toàn bộ quân cờ của người chơi hiện tại.
    
    *   Tất cả các ô quân cờ đó có thể di chuyển tới (theo luật hiện tại của chúng) sẽ được set isVisible = true.
        
*   **Logic hiển thị:** \* Ô có isVisible = false: Không hiển thị quân địch, không hiển thị hiệu ứng ăn quân.
    
    *   Nếu quân địch di chuyển vào vùng tối, nó sẽ biến mất khỏi màn hình của người chơi hiện tại.
        
*   **Chiến thuật AI:** Bot cần có bộ nhớ về vị trí cuối cùng nhìn thấy quân địch (Last Known Position).
    

3\. Blindfold Chess (Cờ Mù - Thử thách trí nhớ)
-----------------------------------------------

Biến thể này tác động vào giao diện (UI Layer) theo tiến trình thời gian.

*   **Bộ đếm nước đi (Move Counter):** Theo dõi totalMoves.
    
*   **Cơ chế ẩn:** \* If totalMoves > 12 (mỗi bên 6 nước): Chuyển opacity của tất cả Asset quân cờ về 0 hoặc thay thế bằng một icon "trống".
    
*   **Sự tương tác:** Người dùng vẫn click vào các ô trống đó để chọn quân (nếu họ nhớ vị trí). AI Agent phải giữ nguyên logic va chạm (Collision) nhưng chặn hiển thị hình ảnh.
    
*   **Tính năng bổ trợ:** Có nút "Peek" (Nhìn trộm) tiêu tốn Gold để hiện lại quân trong 2 giây.
    

4\. Double Blind (Thử thách tối thượng)
---------------------------------------

Đây là sự kết hợp (Matrix) giữa **(1)** và **(2)**. Đây là phần khó nhất cho AI Agent vì nó chồng chéo logic.

*   **Logic kết hợp:**
    
    *   Bạn không biết quân của mình là gì cho đến khi đi (Hidden Identity).
        
    *   Bạn không biết quân địch đang đứng ở đâu nếu ngoài tầm kiểm soát (Fog of War).
        
*   **Tình huống đặc biệt:** Bạn có thể bị ăn bởi một quân cờ địch mà bạn không nhìn thấy, và sau khi bị ăn, quân địch đó mới lật mặt cho bạn thấy nó thực sự là quân gì (nếu nó lọt vào tầm nhìn của bạn sau nước đi đó).
    
*   **Xử lý dữ liệu:** AI phải quản lý một trạng thái "Bàn cờ ảo" cho mỗi người chơi riêng biệt.
    

### Bảng so sánh các Flag logic cho AI triển khai:

**Biến thểisRevealed FlagVisibilityMapUIRenderingHidden Identity**Cần xử lý (False -> True)Full visibilityHiện ảnh Úp/Thật**Fog of War**Mặc định TrueTính toán theo nước điẨn quân địch trong vùng tối**Blindfold**Mặc định TrueFull visibilityẨn hoàn toàn sau 6 nước**Double BlindCần xử lýTính toán theo nước điPhức tạp nhất**

### 💡 Gợi ý cho bạn khi Vibe với DeepSeek:

Hãy bảo DeepSeek viết một **GameModeManager** theo pattern **Strategy**. Mỗi Mode trên sẽ là một class kế thừa từ bản gốc, ghi đè (override) 2 hàm quan trọng nhất:

1.  getAvailableMoves()
    
2.  getVisibleSquares()