package com.dreamplanner.repository;

import com.dreamplanner.entity.Dream;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 梦想数据访问接口
 *
 * @author DreamPlanner
 */
@Repository
public interface DreamRepository extends JpaRepository<Dream, Long> {

    /**
     * 根据用户ID查找梦想列表
     *
     * @param userId 用户ID
     * @return 梦想列表
     */
    List<Dream> findByUserId(Long userId);

    /**
     * 根据用户ID分页查询梦想列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 梦想分页列表
     */
    Page<Dream> findByUserId(Long userId, Pageable pageable);

    /**
     * 根据用户ID和分类查询梦想列表
     *
     * @param userId   用户ID
     * @param category 分类
     * @return 梦想列表
     */
    List<Dream> findByUserIdAndCategory(Long userId, String category);

    /**
     * 根据用户ID和状态查询梦想列表
     *
     * @param userId 用户ID
     * @param status 状态
     * @return 梦想列表
     */
    List<Dream> findByUserIdAndStatus(Long userId, Integer status);

    /**
     * 查询公开的梦想列表（用于社区展示）
     *
     * @param pageable 分页参数
     * @return 公开梦想分页列表
     */
    Page<Dream> findByIsPublic(Integer isPublic, Pageable pageable);

    /**
     * 统计特定梦想的任务数量
     *
     * @param dreamId 梦想ID
     * @return 任务数量
     */
    @Query("SELECT COUNT(t) FROM Task t WHERE t.dream.id = :dreamId")
    Long countTasksByDreamId(@Param("dreamId") Long dreamId);

    /**
     * 统计特定梦想的已完成任务数量
     *
     * @param dreamId 梦想ID
     * @return 已完成任务数量
     */
    @Query("SELECT COUNT(t) FROM Task t WHERE t.dream.id = :dreamId AND t.status = 2")
    Long countCompletedTasksByDreamId(@Param("dreamId") Long dreamId);

    /**
     * 根据用户ID和关键词搜索梦想
     *
     * @param userId   用户ID
     * @param keyword  关键词
     * @param pageable 分页参数
     * @return 梦想分页列表
     */
    @Query("SELECT d FROM Dream d WHERE d.user.id = :userId AND (d.title LIKE %:keyword% OR d.description LIKE %:keyword%)")
    Page<Dream> searchByKeyword(@Param("userId") Long userId, @Param("keyword") String keyword, Pageable pageable);
} 