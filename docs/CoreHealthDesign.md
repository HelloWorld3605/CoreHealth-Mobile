# Home UI Design Guide

## Mục tiêu

Tài liệu này mô tả phong cách thiết kế UI cho trang home của app Flutter theo giao diện hiện tại trong repo, nhưng không cố định các block nội dung. Mục tiêu là giữ đúng tinh thần hình ảnh, màu sắc, spacing và cảm giác sử dụng, để khi thay đổi cấu trúc nội dung vẫn đồng nhất về UI.

## Nguyên tắc chính

- Giao diện sáng, sạch, thân thiện và mang cảm giác wellness.
- Ưu tiên các khối bo tròn lớn, mềm và dễ chạm.
- Dùng màu xanh lá non làm điểm nhấn chính.
- Thị giác cần thoáng, không nhồi nhiều thông tin vào một vùng.
- Các module trên home có thể thay đổi, nhưng phải cùng một hệ thống visual.

## Visual direction

Home screen nên tạo cảm giác:

- Nhẹ
- Tươi
- Có năng lượng
- Cao cấp vừa phải
- Dễ dùng ngay từ cái nhìn đầu tiên

Không nên đi theo hướng:

- Quá kỹ thuật
- Quá tối
- Quá nhiều viền cứng
- Dày đặc text
- Màu nhấn quá gắt

## Design tokens

### Màu sắc

- `#FAFAFA`: nền chính của màn hình.
- `#FFFFFF`: nền của card, surface nổi và nút phụ.
- `#EFEFEF`: nền mockup ngoài thiết bị hoặc nền preview.
- `#DCF58C`: màu nhấn mềm, dùng cho trạng thái nổi bật hoặc vùng cần thu hút.
- `#A6D727`: màu nhấn mạnh, dùng cho CTA hoặc active state quan trọng.
- `#8BC34A`: xanh lá đậm hơn cho progress hoặc accent phụ.
- `#C8E673`: nền phụ cho progress hoặc accent area.
- `#111827`: màu text chính.
- `#6B7280`: màu text phụ.
- `#9CA3AF`: màu text ít quan trọng hơn.
- `#F9FAFB`: nền phụ cho icon button, chip hoặc surface nhỏ.

### Màu phụ trợ

- Cam nhạt cho các trạng thái liên quan đến năng lượng hoặc calories.
- Xanh dương nhạt cho các trạng thái liên quan đến water hoặc hydration.
- Badge active nên dùng accent xanh lá, không dùng đỏ nếu không phải cảnh báo.

### Typography

- Font chính: `Inter`.
- Text chính nên rõ ràng, trọng số từ `500` đến `700`.
- Tiêu đề lớn nên dùng cỡ chữ khoảng `24-28`.
- Tiêu đề card hoặc section nên ở khoảng `17-20`.
- Nội dung phụ nên ở khoảng `13-15`.
- Caption hoặc label nhỏ nên ở khoảng `10-12`.

### Bo góc

- Các block lớn: `24-28`.
- Các button hoặc icon surface: tròn hoàn toàn hoặc bo lớn.
- Các chip nhỏ: dạng capsule.
- Không dùng bo góc sắc hoặc quá nhỏ cho các thành phần chính.

### Shadow

- Shadow rất nhẹ.
- Mục tiêu là tách lớp mềm, không tạo cảm giác nổi quá mạnh.
- Ưu tiên surface sáng với shadow blur mịn hơn là viền dày.

## Bố cục tổng thể

### Mật độ

- Nội dung nên có nhịp thở rõ ràng.
- Khoảng trắng là một phần của thiết kế, không phải vùng trống cần lấp.
- Tránh dồn quá nhiều module có chiều cao nhỏ liên tiếp mà không có nhịp nghỉ.

### Spacing system

- Padding ngang chính: `24`.
- Khoảng cách giữa các module lớn: `20-24`.
- Khoảng cách giữa các phần tử trong cùng một card: `10-16`.
- Khoảng cách giữa icon và label: `8-12`.
- Bottom safe spacing phải đủ để không bị UI hệ thống hoặc navigation che.

### Nhịp bố cục

Home không bị khóa vào một thứ tự component cố định. Tuy nhiên, bố cục nên tuân theo nhịp sau:

- Một vùng mở đầu nhẹ và rõ trọng tâm.
- Một hoặc nhiều surface nội dung nổi bật.
- Các module thông tin đặt theo nhóm.
- Khu vực thao tác chính hoặc navigation phải dễ chạm và ổn định ở đáy màn hình nếu có.

Điều quan trọng là hierarchy thị giác, không phải tên module.

## Pattern UI nên giữ

### Surface cards

- Card nền trắng.
- Bo góc lớn.
- Border rất nhạt hoặc không cần border nếu shadow đã đủ.
- Padding trong rộng, tránh cảm giác chật.
- Nội dung trong card nên có 1 trọng tâm chính và 1 lớp thông tin phụ.

### Icon buttons

- Dạng tròn hoặc gần tròn.
- Nền sáng.
- Kích thước tap thoải mái, khoảng `40-44`.
- Nếu có badge, badge phải nhỏ và tinh tế.

### Accent blocks

- Những vùng cần nổi bật có thể dùng xanh lá non.
- Accent không nên xuất hiện quá dày đặc.
- Mỗi màn nên chỉ có `1-2` vùng nhấn thực sự nổi bật.

### Chips và tags

- Nền nhẹ, chữ đậm vừa.
- Bo tròn đầy đủ.
- Có thể đi kèm icon nhỏ.
- Dùng để tạo nhịp hoặc nhóm thông tin, không nên lạm dụng.

### Avatar và ảnh tròn

- Ảnh dạng tròn, crop sát, viền sáng mỏng.
- Nếu nhiều ảnh xếp chồng, phần overlap nên vừa phải để vẫn nhận ra từng ảnh.

## Trạng thái tương tác

- Active state nên dùng accent xanh lá hoặc text đậm hơn.
- Hover hoặc pressed state cần nhẹ, không nhảy màu quá mạnh.
- Các button phụ nên đổi nền rất nhẹ khi tap.
- Thành phần được chọn nên có sự khác biệt rõ nhưng vẫn tinh tế.

## Cảm giác chuyển động

Motion nên ngắn, mềm và ít:

- Duration khoảng `150ms - 250ms`.
- Ưu tiên fade nhẹ, scale nhẹ hoặc color transition.
- Tránh animation nảy mạnh hoặc quá "game-like".

## Nội dung và hierarchy

UI nên phân cấp thông tin như sau:

- Thông tin chính: to, đậm, dễ nhìn ngay.
- Thông tin hỗ trợ: nhỏ hơn, màu nhẹ hơn.
- Hành động chính: nổi bật bằng màu hoặc vị trí.
- Hành động phụ: nhẹ hơn, không tranh chấp với CTA chính.

Một block tốt là block mà người dùng nhìn `1-2` giây đã hiểu đâu là nội dung chính.

## Responsive cho Flutter

- Ưu tiên thiết kế mobile-first.
- Trên màn hẹp, các block nên tự co theo chiều dọc thay vì ép ngang quá chặt.
- Trên màn lớn hơn, có thể tăng padding hoặc khoảng cách trước khi tăng kích thước chữ quá nhiều.
- Tôn trọng `SafeArea`.
- Không phụ thuộc vào mockup khung máy như bản web preview.

## Điều không nên cố định

Tài liệu này không yêu cầu home phải có sẵn các phần như:

- Header kiểu greeting
- Thẻ progress tuần
- Lịch
- Meal card
- Bottom navigation kiểu hiện tại

Các phần trên chỉ là biểu hiện của UI hiện tại trong mockup. Khi triển khai Flutter, có thể thay bằng module khác miễn là vẫn giữ:

- Cùng hệ màu
- Cùng nhịp spacing
- Cùng độ bo góc
- Cùng mức shadow
- Cùng hierarchy thị giác
- Cùng cảm giác wellness, sáng và mềm

## Checklist để review UI

- Nền tổng thể có đủ sáng và thoáng không.
- Màu accent xanh lá có đang được dùng đúng mức không.
- Các card có cùng ngôn ngữ bo góc và shadow không.
- Khoảng cách giữa các khối có đều và dễ thở không.
- Thành phần quan trọng nhất trên màn có nổi bật ngay không.
- Text chính và text phụ có tách bạch rõ không.
- Các nút chạm có đủ lớn và dễ hiểu không.
- Màn hình có giữ được cảm giác hiện đại, mềm và sạch không.

## Tham chiếu từ UI hiện tại

UI hiện tại trong repo cho thấy rõ một số đặc trưng nên giữ:

- Nền sáng gần trắng.
- Card trắng nổi nhẹ trên nền.
- Accent xanh lá non rất rõ nhưng không quá chói.
- Nội dung được chia thành các module bo tròn lớn.
- Icon và hành động phụ có phong cách nhẹ, tối giản.

Phần này chỉ dùng làm chuẩn thẩm mỹ, không phải danh sách component bắt buộc.

## Kết luận

Trang home nên được xem như một hệ thiết kế mềm và nhất quán, không phải một layout cứng. Khi làm Flutter, ưu tiên giữ đúng "chất UI" của màn hình hiện tại hơn là sao chép nguyên thứ tự các section.
