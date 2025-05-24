package com.dreamplanner.repository;

import com.dreamplanner.entity.Follow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * 关注关系数据访问接口
 *
 * @author DreamPlanner
 */
@Repository
public interface FollowRepository extends JpaRepository<Follow, Long> {

    /**
     * 通过关注者ID和被关注者ID查找关注关系
     *
     * @param followerId 关注者ID
     * @param followedId 被关注者ID
     * @return 可选的关注关系
     */
    @Query(value = "SELECT * FROM follow WHERE follower_id = :followerId AND following_id = :followedId", nativeQuery = true)
    Optional<Follow> findByFollowerIdAndFollowedId(@Param("followerId") Long followerId, @Param("followedId") Long followedId);

    /**
     * 查询用户的粉丝数量
     *
     * @param userId 用户ID
     * @return 粉丝数量
     */
    @Query(value = "SELECT COUNT(*) FROM follow WHERE following_id = :userId", nativeQuery = true)
    Long countByFollowedId(@Param("userId") Long userId);

    /**
     * 查询用户关注的人数
     *
     * @param userId 用户ID
     * @return 关注数量
     */
    @Query(value = "SELECT COUNT(*) FROM follow WHERE follower_id = :userId", nativeQuery = true)
    Long countByFollowerId(@Param("userId") Long userId);

    /**
     * 获取用户的粉丝ID列表
     *
     * @param userId 用户ID
     * @return 粉丝ID列表
     */
    @Query(value = "SELECT follower_id FROM follow WHERE following_id = :userId", nativeQuery = true)
    List<Long> findFollowerIdsByUserId(@Param("userId") Long userId);

    /**
     * 获取用户关注的用户ID列表
     *
     * @param userId 用户ID
     * @return 关注的用户ID列表
     */
    @Query(value = "SELECT following_id FROM follow WHERE follower_id = :userId", nativeQuery = true)
    List<Long> findFollowedIdsByUserId(@Param("userId") Long userId);

    /**
     * 删除关注关系
     *
     * @param followerId 关注者ID
     * @param followedId 被关注者ID
     */
    @Modifying
    @Transactional
    @Query(value = "DELETE FROM follow WHERE follower_id = :followerId AND following_id = :followedId", nativeQuery = true)
    void deleteByFollowerIdAndFollowedId(@Param("followerId") Long followerId, @Param("followedId") Long followedId);
} 