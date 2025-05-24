package com.dreamplanner.service;

import com.dreamplanner.dto.UserDTO;
import com.dreamplanner.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * 用户服务接口
 *
 * @author DreamPlanner
 */
public interface UserService {

    /**
     * 根据ID获取用户
     *
     * @param userId 用户ID
     * @return 用户信息
     */
    UserDTO getUserById(Long userId);

    /**
     * 根据用户名获取用户
     *
     * @param username 用户名
     * @return 用户信息
     */
    UserDTO getUserByUsername(String username);

    /**
     * 根据邮箱获取用户
     *
     * @param email 邮箱
     * @return 用户信息
     */
    User getUserByEmail(String email);

    /**
     * 创建新用户
     *
     * @param userDTO 用户信息
     * @return 创建后的用户
     */
    UserDTO createUser(UserDTO userDTO);

    /**
     * 更新用户信息
     *
     * @param id 用户ID
     * @param userDTO 用户信息
     * @return 更新后的用户
     */
    UserDTO updateUser(Long id, UserDTO userDTO);

    /**
     * 更新用户密码
     *
     * @param userId      用户ID
     * @param oldPassword 旧密码
     * @param newPassword 新密码
     * @return 是否更新成功
     */
    boolean updatePassword(Long userId, String oldPassword, String newPassword);

    /**
     * 检查用户名是否可用
     *
     * @param username 用户名
     * @return 是否可用
     */
    boolean isUsernameAvailable(String username);

    /**
     * 检查邮箱是否可用
     *
     * @param email 邮箱
     * @return 是否可用
     */
    boolean isEmailAvailable(String email);

    /**
     * 检查手机号是否可用
     *
     * @param phone 手机号
     * @return 可用返回true，否则返回false
     */
    boolean isPhoneAvailable(String phone);

    /**
     * 关注用户
     *
     * @param followerId  关注者ID
     * @param followedId 被关注者ID
     */
    void followUser(Long followerId, Long followedId);

    /**
     * 取消关注用户
     *
     * @param followerId  关注者ID
     * @param followedId 被关注者ID
     */
    void unfollowUser(Long followerId, Long followedId);

    /**
     * 检查是否已关注用户
     *
     * @param followerId  关注者ID
     * @param followedId 被关注者ID
     * @return 已关注返回true，否则返回false
     */
    boolean isFollowing(Long followerId, Long followedId);

    /**
     * 获取用户关注列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 关注用户分页列表
     */
    Page<UserDTO> getFollowings(Long userId, Pageable pageable);

    /**
     * 获取用户粉丝列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 粉丝用户分页列表
     */
    Page<UserDTO> getFollowers(Long userId, Pageable pageable);
    
    /**
     * 获取所有用户
     *
     * @param pageable 分页参数
     * @return 用户分页列表
     */
    Page<UserDTO> getAllUsers(Pageable pageable);
    
    /**
     * 删除用户
     *
     * @param id 用户ID
     */
    void deleteUser(Long id);
} 