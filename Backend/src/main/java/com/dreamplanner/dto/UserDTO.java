package com.dreamplanner.dto;

import com.dreamplanner.entity.User;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 用户数据传输对象
 * 用于前端展示和数据传输的用户信息
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "用户信息")
public class UserDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    @Schema(description = "用户ID")
    private Long id;

    @Schema(description = "用户名")
    private String username;

    @Schema(description = "密码")
    private String password;

    @Schema(description = "昵称")
    private String nickname;

    @Schema(description = "头像")
    private String avatar;

    @Schema(description = "邮箱")
    private String email;

    @Schema(description = "手机号")
    private String phone;

    @Schema(description = "性别：0-未知，1-男，2-女")
    private Integer gender;

    @Schema(description = "生日")
    private LocalDate birthday;

    @Schema(description = "个性签名")
    private String signature;

    @Schema(description = "状态：0-禁用，1-正常")
    private Integer status;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;

    @Schema(description = "梦想数量")
    private Long dreamsCount;

    @Schema(description = "已完成梦想数量")
    private Long completedDreamsCount;

    @Schema(description = "任务数量")
    private Long tasksCount;

    @Schema(description = "粉丝数量")
    private Long followersCount;

    @Schema(description = "关注数量")
    private Long followingCount;

    @Schema(description = "是否已关注该用户")
    private Boolean isFollowing;

    /**
     * 从User实体转换为UserDTO
     *
     * @param user User实体
     * @return UserDTO对象
     */
    public static UserDTO fromUser(User user) {
        if (user == null) {
            return null;
        }
        
        UserDTO userDTO = new UserDTO();
        userDTO.setId(user.getId());
        userDTO.setUsername(user.getUsername());
        userDTO.setNickname(user.getNickname());
        userDTO.setAvatar(user.getAvatar());
        userDTO.setEmail(user.getEmail());
        userDTO.setPhone(user.getPhone());
        userDTO.setGender(user.getGender());
        userDTO.setBirthday(user.getBirthday());
        userDTO.setSignature(user.getSignature());
        userDTO.setStatus(user.getStatus());
        userDTO.setCreatedAt(user.getCreateTime());
        
        // 这些字段需要在Service层计算设置
        // userDTO.setFollowingCount(user.getFollowing().size());
        // userDTO.setFollowersCount(user.getFollowers().size());
        // userDTO.setDreamsCount(user.getDreams().size());
        
        return userDTO;
    }

    /**
     * 将UserDTO转换为User实体
     *
     * @return User实体
     */
    public User toUser() {
        User user = new User();
        
        // 只设置必要的字段，其他字段可能需要在服务层设置
        if (this.id != null) {
            user.setId(this.id);
        }
        user.setUsername(this.username);
        if (this.password != null) {
            user.setPassword(this.password);
        }
        user.setNickname(this.nickname);
        user.setAvatar(this.avatar);
        user.setEmail(this.email);
        user.setPhone(this.phone);
        user.setGender(this.gender);
        user.setBirthday(this.birthday);
        user.setSignature(this.signature);
        user.setStatus(this.status != null ? this.status : 1); // 默认状态为正常
        
        return user;
    }
} 