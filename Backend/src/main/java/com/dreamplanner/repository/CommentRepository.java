package com.dreamplanner.repository;

import com.dreamplanner.entity.Comment;
import com.dreamplanner.entity.Post;
import com.dreamplanner.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 评论仓库接口
 *
 * @author DreamPlanner
 */
@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {

    /**
     * 根据动态查询所有评论，按创建时间降序排序
     *
     * @param post 动态
     * @param pageable 分页参数
     * @return 分页评论列表
     */
    Page<Comment> findByPostOrderByCreatedAtDesc(Post post, Pageable pageable);

    /**
     * 根据动态和状态查询所有一级评论（无父评论的评论），按创建时间降序排序
     *
     * @param post 动态
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页评论列表
     */
    List<Comment> findByPostAndParentIsNullAndStatusOrderByCreatedAtDesc(Post post, Integer status, Pageable pageable);
    
    /**
     * 根据动态和状态查询所有一级评论（parentId为null的评论），按创建时间降序排序
     *
     * @param post 动态
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页评论列表
     */
    List<Comment> findByPostAndParentIdIsNullAndStatusOrderByCreatedAtDesc(Post post, Integer status, Pageable pageable);

    /**
     * 根据父评论和状态查询所有回复，按创建时间升序排序
     *
     * @param parent 父评论
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页评论列表
     */
    List<Comment> findByParentAndStatusOrderByCreatedAtAsc(Comment parent, Integer status, Pageable pageable);
    
    /**
     * 根据父评论ID和状态查询所有回复，按创建时间升序排序
     *
     * @param parentId 父评论ID
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页评论列表
     */
    List<Comment> findByParentIdAndStatusOrderByCreatedAtAsc(Long parentId, Integer status, Pageable pageable);

    /**
     * 根据用户查询所有评论，按创建时间降序排序
     *
     * @param user 用户
     * @param pageable 分页参数
     * @return 分页评论列表
     */
    Page<Comment> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    /**
     * 根据动态查询评论数量
     *
     * @param post 动态
     * @return 评论数量
     */
    long countByPost(Post post);
} 