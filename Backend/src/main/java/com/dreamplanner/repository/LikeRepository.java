package com.dreamplanner.repository;

import com.dreamplanner.entity.Comment;
import com.dreamplanner.entity.Like;
import com.dreamplanner.entity.Post;
import com.dreamplanner.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 点赞仓库接口
 *
 * @author DreamPlanner
 */
@Repository
public interface LikeRepository extends JpaRepository<Like, Long> {

    /**
     * 根据动态和用户查询点赞记录
     *
     * @param post 动态
     * @param user 用户
     * @return 点赞记录
     */
    Optional<Like> findByPostAndUser(Post post, User user);

    /**
     * 根据评论和用户查询点赞记录
     *
     * @param comment 评论
     * @param user 用户
     * @return 点赞记录
     */
    Optional<Like> findByCommentAndUser(Comment comment, User user);

    /**
     * 根据动态查询点赞数量
     *
     * @param post 动态
     * @return 点赞数量
     */
    long countByPost(Post post);

    /**
     * 根据评论查询点赞数量
     *
     * @param comment 评论
     * @return 点赞数量
     */
    long countByComment(Comment comment);
} 