package com.dreamplanner.repository;

import com.dreamplanner.entity.Dream;
import com.dreamplanner.entity.Post;
import com.dreamplanner.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 社区动态仓库接口
 *
 * @author DreamPlanner
 */
@Repository
public interface PostRepository extends JpaRepository<Post, Long> {

    /**
     * 根据状态查询动态，按创建时间降序排序
     *
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    Page<Post> findByStatusOrderByCreatedAtDesc(Integer status, Pageable pageable);
    
    /**
     * 根据用户ID列表和状态查询动态，按创建时间降序排序
     *
     * @param userIds 用户ID列表
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    Page<Post> findByUserIdInAndStatusOrderByCreatedAtDesc(List<Long> userIds, Integer status, Pageable pageable);
    
    /**
     * 查询热门动态，综合点赞数、评论数和浏览数排序
     *
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    @Query("SELECT p FROM Post p WHERE p.status = :status " +
           "ORDER BY (p.likeCount * 3 + p.commentCount * 2 + p.viewCount) DESC")
    Page<Post> findHotPosts(@Param("status") Integer status, Pageable pageable);
    
    /**
     * 根据用户和状态查询动态，按创建时间降序排序
     *
     * @param user 用户
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    Page<Post> findByUserAndStatusOrderByCreatedAtDesc(User user, Integer status, Pageable pageable);
    
    /**
     * 根据梦想和状态查询动态，按创建时间降序排序
     *
     * @param dream 梦想
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    Page<Post> findByDreamAndStatusOrderByCreatedAtDesc(Dream dream, Integer status, Pageable pageable);
    
    /**
     * 根据用户和状态查询动态
     *
     * @param user 用户
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    Page<Post> findByUserAndStatus(User user, Integer status, Pageable pageable);
    
    /**
     * 根据状态查询动态
     *
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    Page<Post> findByStatus(Integer status, Pageable pageable);
    
    /**
     * 根据梦想分类和状态查询动态
     *
     * @param category 梦想分类
     * @param status 状态
     * @param pageable 分页参数
     * @return 分页动态列表
     */
    @Query("SELECT p FROM Post p WHERE p.dream.category = :category AND p.status = :status")
    Page<Post> findByDreamCategoryAndStatus(@Param("category") String category, @Param("status") Integer status, Pageable pageable);
} 