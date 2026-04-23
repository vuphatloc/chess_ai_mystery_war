Trong cờ vua, Cờ Chớp (Blitz) là thể loại mà yếu tố thời gian cực kỳ quan trọng, đôi khi còn quan trọng hơn cả chiến thuật trên bàn cờ. Đây là "đặc sản" của các kỳ thủ có khả năng phản xạ nhanh và trực giác tốt.

Dưới đây là các quy định về thời gian cho cờ chớp:

1. Khung thời gian tiêu chuẩn
Theo quy định của Liên đoàn Cờ vua Thế giới (FIDE), cờ chớp được tính khi mỗi bên có từ 10 phút trở xuống cho toàn bộ ván đấu.

Các mốc phổ biến nhất là:

3 phút: Mỗi bên có tổng 3 phút.

5 phút: Mỗi bên có tổng 5 phút.

3 phút + 2 giây: Mỗi bên có 3 phút ban đầu, sau mỗi nước đi sẽ được cộng thêm 2 giây (đây là thể loại phổ biến nhất trên các app như Chess.com).

2. Hai chế độ tính giờ phổ biến
Khi code game bằng Flutter, bạn sẽ cần để ý 2 cơ chế đồng hồ này:

Sudden Death (Cái chết bất đắc kỳ tử): Bạn có 3 phút hoặc 5 phút cố định. Nếu đồng hồ về 0, bạn thua ngay lập tức, bất kể thế trận đang thắng hay thua.

Increment (Cộng giờ - Luật Fischer): Sau mỗi nước đi, một khoảng thời gian nhỏ (thường là 2 giây hoặc 3 giây) được cộng thêm vào quỹ thời gian của bạn. Điều này giúp tránh việc ván đấu kết thúc chỉ vì một người lỡ tay không bấm kịp đồng hồ khi thế trận đang thắng tuyệt đối.

3. Tại sao Cờ Chớp lại hợp với "Mystery War" của bạn?
Kết hợp cờ chớp vào biến thể Cờ Vua Úp sẽ tạo ra một trải nghiệm "hỗn loạn" đầy thú vị:

Áp lực tâm lý: Người chơi vừa phải đoán quân cờ úp là gì, vừa phải nhìn đồng hồ đang nhảy ngược.

Sai lầm kịch tính: Trong cờ chớp, người chơi dễ đi nhầm. Với cờ úp, sai lầm đó có thể dẫn đến việc lật nhầm quân cờ yếu vào vị trí nguy hiểm, tạo ra những pha "lật kèo" cực mạnh.

💡 Gợi ý đưa vào SRS (Phần Game Rules):
Để game hấp dẫn, bạn nên chia các mức thời gian theo chế độ chơi:

Bullet (Siêu chớp): 1 phút hoặc 2 phút (Dành cho cao thủ, cực nhanh).

Blitz (Cờ chớp): 3 phút hoặc 5 phút (Mức phổ biến nhất).

Rapid (Cờ nhanh): 10 phút (Dành cho người muốn suy nghĩ kỹ hơn một chút).

Lưu ý kỹ thuật cho Flutter:
Khi bạn "vibe" với DeepSeek về phần này, hãy yêu cầu nó viết một TimerService sử dụng Stream hoặc Ticker trong Flutter để đảm bảo đồng hồ chạy chính xác từng miligiây và đồng bộ giữa hai bên người chơi.