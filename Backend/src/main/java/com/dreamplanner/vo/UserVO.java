package com.dreamplanner.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户视图对象
 * 用于前端展示的用户简要信息，主要用于列表展示和关联数据中
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserVO {
    /**
     * 用户ID
     */
    private Long id;
    
    /**
     * 用户名
     */
    private String username;
    
    /**
     * 昵称
     */
    private String nickname;
    
    /**
     * 头像URL
     */
    private String avatar;
    
    /**
     * 是否被当前用户关注
     */
    private Boolean isFollowed;
} 