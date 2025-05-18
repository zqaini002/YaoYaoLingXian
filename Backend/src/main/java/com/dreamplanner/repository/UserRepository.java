package com.dreamplanner.repository;

import com.dreamplanner.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 用户数据访问接口
 *
 * @author DreamPlanner
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * 根据用户名查找用户
     *
     * @param username 用户名
     * @return 用户信息
     */
    Optional<User> findByUsername(String username);

    /**
     * 根据邮箱查找用户
     *
     * @param email 邮箱
     * @return 用户信息
     */
    Optional<User> findByEmail(String email);

    /**
     * 根据手机号查找用户
     *
     * @param phone 手机号
     * @return 用户信息
     */
    Optional<User> findByPhone(String phone);

    /**
     * 检查用户名是否存在
     *
     * @param username 用户名
     * @return 存在返回true，否则返回false
     */
    boolean existsByUsername(String username);

    /**
     * 检查邮箱是否存在
     *
     * @param email 邮箱
     * @return 存在返回true，否则返回false
     */
    boolean existsByEmail(String email);

    /**
     * 检查手机号是否存在
     *
     * @param phone 手机号
     * @return 存在返回true，否则返回false
     */
    boolean existsByPhone(String phone);
    
    /**
     * 统计用户的梦想数量
     *
     * @param userId 用户ID
     * @return 梦想数量
     */
    @Query("SELECT COUNT(d) FROM Dream d WHERE d.user.id = :userId")
    Long countDreamsByUserId(@Param("userId") Long userId);
    
    /**
     * 统计用户的已完成梦想数量
     *
     * @param userId 用户ID
     * @return 已完成梦想数量
     */
    @Query("SELECT COUNT(d) FROM Dream d WHERE d.user.id = :userId AND d.status = 2")
    Long countCompletedDreamsByUserId(@Param("userId") Long userId);
    
    /**
     * 统计用户的任务数量
     *
     * @param userId 用户ID
     * @return 任务数量
     */
    @Query("SELECT COUNT(t) FROM Task t WHERE t.user.id = :userId")
    Long countTasksByUserId(@Param("userId") Long userId);
    
    /**
     * 查询用户的粉丝用户列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 粉丝用户分页列表
     */
    @Query("SELECT f.follower FROM Follow f WHERE f.followed.id = :userId")
    Page<User> findFollowersByUserId(@Param("userId") Long userId, Pageable pageable);
    
    /**
     * 查询用户关注的用户列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 关注的用户分页列表
     */
    @Query("SELECT f.followed FROM Follow f WHERE f.follower.id = :userId")
    Page<User> findFollowedUsersByUserId(@Param("userId") Long userId, Pageable pageable);
} 