package com.dreamplanner.repository;

import com.dreamplanner.entity.Task;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

/**
 * 任务数据访问接口
 *
 * @author DreamPlanner
 */
@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    /**
     * 根据梦想ID查询任务列表
     *
     * @param dreamId 梦想ID
     * @return 任务列表
     */
    List<Task> findByDreamId(Long dreamId);

    /**
     * 根据梦想ID分页查询任务列表
     *
     * @param dreamId  梦想ID
     * @param pageable 分页参数
     * @return 任务分页列表
     */
    Page<Task> findByDreamId(Long dreamId, Pageable pageable);

    /**
     * 根据用户ID查询任务列表
     *
     * @param userId 用户ID
     * @return 任务列表
     */
    List<Task> findByUserId(Long userId);

    /**
     * 根据用户ID分页查询任务列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 任务分页列表
     */
    Page<Task> findByUserId(Long userId, Pageable pageable);

    /**
     * 根据梦想ID和状态查询任务列表
     *
     * @param dreamId 梦想ID
     * @param status  状态
     * @return 任务列表
     */
    List<Task> findByDreamIdAndStatus(Long dreamId, Integer status);

    /**
     * 根据用户ID和状态查询任务列表
     *
     * @param userId 用户ID
     * @param status 状态
     * @return 任务列表
     */
    List<Task> findByUserIdAndStatus(Long userId, Integer status);

    /**
     * 查询用户今日任务
     * 修改为返回更广泛的任务集合:
     * 1. 今天开始或今天截止的任务
     * 2. 已经开始但尚未完成的任务（进行中）
     * 3. 7天内即将到期的任务
     * 结果按优先级和截止日期排序
     *
     * @param userId    用户ID
     * @param today     今天日期
     * @param pageable  分页参数
     * @return 任务分页列表
     */
    @Query("SELECT t FROM Task t WHERE t.user.id = :userId AND " +
           "(" +
           "  (t.startDate = :today OR t.dueDate = :today) OR " +
           "  (t.startDate < :today AND (t.dueDate IS NULL OR t.dueDate >= :today)) OR " +
           "  (t.dueDate IS NOT NULL AND t.dueDate > :today AND t.dueDate <= :endDate)" +
           ") " +
           "AND t.status != 2 " +
           "ORDER BY " +
           "CASE WHEN t.dueDate = :today THEN 0 " +
           "     WHEN t.startDate = :today THEN 1 " +
           "     ELSE 2 END, " +
           "t.priority, " +
           "CASE WHEN t.dueDate IS NULL THEN 1 ELSE 0 END, " +
           "t.dueDate")
    Page<Task> findTodayTasks(@Param("userId") Long userId, @Param("today") LocalDate today, 
                              @Param("endDate") LocalDate endDate, Pageable pageable);

    /**
     * 查询用户未来7天任务
     *
     * @param userId     用户ID
     * @param startDate  开始日期
     * @param endDate    结束日期
     * @param pageable   分页参数
     * @return 任务分页列表
     */
    @Query("SELECT t FROM Task t WHERE t.user.id = :userId AND (t.startDate BETWEEN :startDate AND :endDate OR t.dueDate BETWEEN :startDate AND :endDate) AND t.status != 2")
    Page<Task> findWeekTasks(@Param("userId") Long userId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate, Pageable pageable);

    /**
     * 查询用户即将到期的任务
     *
     * @param userId   用户ID
     * @param dueDate  截止日期
     * @param pageable 分页参数
     * @return 任务分页列表
     */
    @Query("SELECT t FROM Task t WHERE t.user.id = :userId AND t.dueDate <= :dueDate AND t.status != 2")
    Page<Task> findUpcomingTasks(@Param("userId") Long userId, @Param("dueDate") LocalDate dueDate, Pageable pageable);

    /**
     * 查询父任务的子任务列表
     *
     * @param parentTaskId 父任务ID
     * @return 子任务列表
     */
    List<Task> findByParentTaskId(Long parentTaskId);
    
    /**
     * 根据用户ID和关键词搜索任务
     *
     * @param userId   用户ID
     * @param keyword  关键词
     * @param pageable 分页参数
     * @return 任务分页列表
     */
    @Query("SELECT t FROM Task t WHERE t.user.id = :userId AND (t.title LIKE %:keyword% OR t.description LIKE %:keyword%)")
    Page<Task> searchByKeyword(@Param("userId") Long userId, @Param("keyword") String keyword, Pageable pageable);
    
    /**
     * 统计用户的任务总数
     *
     * @param userId 用户ID
     * @return 任务总数
     */
    Long countByUserId(Long userId);
    
    /**
     * 统计用户指定状态的任务数量
     *
     * @param userId 用户ID
     * @param status 状态
     * @return 指定状态的任务数量
     */
    Long countByUserIdAndStatus(Long userId, Integer status);
} 