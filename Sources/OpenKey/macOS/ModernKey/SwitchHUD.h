//
//  SwitchHUD.h
//  KietKey
//
//  Báo hiệu giữa màn hình khi chuyển tiếng Việt / English.
//
//  Hành vi (phương án A):
//   - HUD hiện ra là đã sẵn chữ của trạng thái mới, không trượt.
//   - Chỉ trượt khi người dùng chuyển tiếp lúc HUD còn đang hiện.
//   - Hiện ~0,6 giây rồi mờ đi.
//
//  Tắt tính năng:
//    defaults write com.tuyenmai.openkey vShowSwitchHUD -int 0
//

#ifndef SwitchHUD_h
#define SwitchHUD_h

#import <Foundation/Foundation.h>

/// Hiện HUD cho trạng thái hiện tại. vietnamese = YES -> "V", NO -> "E".
void SwitchHUDShow(BOOL vietnamese);

/// Ẩn ngay và huỷ hẹn giờ. Gọi khi thoát ứng dụng.
void SwitchHUDDismiss(void);

#endif /* SwitchHUD_h */
