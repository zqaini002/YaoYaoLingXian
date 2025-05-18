package com.dreamplanner.service.impl;

import com.dreamplanner.dto.UserDTO;
import com.dreamplanner.entity.Follow;
import com.dreamplanner.entity.User;
import com.dreamplanner.exception.ResourceNotFoundException;
import com.dreamplanner.repository.FollowRepository;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 用户服务实现类
 *
 * @author DreamPlanner
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final FollowRepository followRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public UserDTO getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));
        return convertToDTO(user);
    }

    @Override
    public UserDTO getUserByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));
        return convertToDTO(user);
    }

    @Override
    @Transactional
    public UserDTO createUser(UserDTO userDTO) {
        // 检查用户名是否已存在
        if (!isUsernameAvailable(userDTO.getUsername())) {
            throw new IllegalArgumentException("用户名已被使用");
        }
        
        // 检查邮箱是否已存在
        if (userDTO.getEmail() != null && !isEmailAvailable(userDTO.getEmail())) {
            throw new IllegalArgumentException("邮箱已被使用");
        }
        
        // 检查手机号是否已存在
        if (userDTO.getPhone() != null && !isPhoneAvailable(userDTO.getPhone())) {
            throw new IllegalArgumentException("手机号已被使用");
        }
        
        // 将DTO转换为实体
        User user = userDTO.toUser();
        
        // 加密密码，如果密码为空则设置默认密码
        if (user.getPassword() == null || user.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(user.getUsername())); // 默认密码为用户名
        } else {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        
        // 设置默认状态
        if (user.getStatus() == null) {
            user.setStatus(1); // 默认状态为正常
        }
        
        User savedUser = userRepository.save(user);
        log.info("创建用户成功: {}", savedUser.getUsername());
        return convertToDTO(savedUser);
    }

    @Override
    @Transactional
    public UserDTO updateUser(Long id, UserDTO userDTO) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));
        
        // 不允许修改用户名
        if (userDTO.getNickname() != null) {
            user.setNickname(userDTO.getNickname());
        }
        if (userDTO.getAvatar() != null) {
            user.setAvatar(userDTO.getAvatar());
        }
        if (userDTO.getEmail() != null && !user.getEmail().equals(userDTO.getEmail())) {
            if (!isEmailAvailable(userDTO.getEmail())) {
                throw new IllegalArgumentException("邮箱已被使用");
            }
            user.setEmail(userDTO.getEmail());
        }
        if (userDTO.getPhone() != null && !user.getPhone().equals(userDTO.getPhone())) {
            if (!isPhoneAvailable(userDTO.getPhone())) {
                throw new IllegalArgumentException("手机号已被使用");
            }
            user.setPhone(userDTO.getPhone());
        }
        if (userDTO.getGender() != null) {
            user.setGender(userDTO.getGender());
        }
        if (userDTO.getBirthday() != null) {
            user.setBirthday(userDTO.getBirthday());
        }
        if (userDTO.getSignature() != null) {
            user.setSignature(userDTO.getSignature());
        }
        
        User updatedUser = userRepository.save(user);
        log.info("更新用户信息成功: {}", updatedUser.getUsername());
        return convertToDTO(updatedUser);
    }

    @Override
    public Page<UserDTO> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable)
                .map(this::convertToDTO);
    }

    @Override
    @Transactional
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));
        
        // 设置用户状态为禁用，而不是物理删除
        user.setStatus(0);
        userRepository.save(user);
        log.info("禁用用户成功: {}", user.getUsername());
    }

    @Override
    public boolean isUsernameAvailable(String username) {
        return !userRepository.existsByUsername(username);
    }

    @Override
    public boolean isEmailAvailable(String email) {
        return !userRepository.existsByEmail(email);
    }

    @Override
    public boolean isPhoneAvailable(String phone) {
        return !userRepository.existsByPhone(phone);
    }

    @Override
    @Transactional
    public void followUser(Long followerId, Long followedId) {
        if (followerId.equals(followedId)) {
            throw new IllegalArgumentException("不能关注自己");
        }
        
        User follower = userRepository.findById(followerId)
                .orElseThrow(() -> new ResourceNotFoundException("关注者不存在"));
        
        User followed = userRepository.findById(followedId)
                .orElseThrow(() -> new ResourceNotFoundException("被关注者不存在"));
        
        if (isFollowing(followerId, followedId)) {
            throw new IllegalArgumentException("已经关注过该用户");
        }
        
        Follow follow = Follow.builder()
                .follower(follower)
                .followed(followed)
                .build();
        
        followRepository.save(follow);
        log.info("用户关注成功: {} -> {}", follower.getUsername(), followed.getUsername());
    }

    @Override
    @Transactional
    public void unfollowUser(Long followerId, Long followedId) {
        if (!isFollowing(followerId, followedId)) {
            throw new IllegalArgumentException("未关注该用户");
        }
        
        followRepository.deleteByFollowerIdAndFollowedId(followerId, followedId);
        log.info("取消关注成功: {} -> {}", followerId, followedId);
    }

    @Override
    public boolean isFollowing(Long followerId, Long followedId) {
        return followRepository.findByFollowerIdAndFollowedId(followerId, followedId).isPresent();
    }

    @Override
    public Page<UserDTO> getFollowings(Long userId, Pageable pageable) {
        return userRepository.findFollowedUsersByUserId(userId, pageable)
                .map(user -> convertToDTO(user));
    }

    @Override
    public Page<UserDTO> getFollowers(Long userId, Pageable pageable) {
        return userRepository.findFollowersByUserId(userId, pageable)
                .map(user -> convertToDTO(user));
    }

    @Override
    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("该邮箱对应的用户不存在"));
    }

    @Override
    @Transactional
    public boolean updatePassword(Long userId, String oldPassword, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在"));
        
        // 验证旧密码
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            return false;
        }
        
        // 更新密码
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        log.info("用户密码更新成功: {}", user.getUsername());
        return true;
    }

    /**
     * 将用户实体转换为DTO
     *
     * @param user 用户实体
     * @return 用户DTO
     */
    private UserDTO convertToDTO(User user) {
        // 统计用户数据
        Long dreamsCount = userRepository.countDreamsByUserId(user.getId());
        Long completedDreamsCount = userRepository.countCompletedDreamsByUserId(user.getId());
        Long tasksCount = userRepository.countTasksByUserId(user.getId());
        Long followersCount = followRepository.countByFollowedId(user.getId());
        Long followingCount = followRepository.countByFollowerId(user.getId());
        
        return UserDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .nickname(user.getNickname())
                .avatar(user.getAvatar())
                .email(user.getEmail())
                .phone(user.getPhone())
                .gender(user.getGender())
                .birthday(user.getBirthday())
                .signature(user.getSignature())
                .status(user.getStatus())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .dreamsCount(dreamsCount)
                .completedDreamsCount(completedDreamsCount)
                .tasksCount(tasksCount)
                .followersCount(followersCount)
                .followingCount(followingCount)
                .build();
    }
} 