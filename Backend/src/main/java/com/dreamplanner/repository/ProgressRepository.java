package com.dreamplanner.repository;

import com.dreamplanner.entity.Progress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 进度记录数据访问接口
 *
 * @author DreamPlanner
 */
@Repository
public interface ProgressRepository extends JpaRepository<Progress, Long> {

    /**
     * 根据任务ID查询进度记录列表
     *
     * @param taskId 任务ID
     * @return 进度记录列表
     */
    List<Progress> findByTaskId(Long taskId);

    /**
     * 根据梦想ID查询进度记录列表
     *
     * @param dreamId 梦想ID
     * @return 进度记录列表
     */
    List<Progress> findByDreamId(Long dreamId);

    /**
     * 根据用户ID查询进度记录列表
     *
     * @param userId 用户ID
     * @return 进度记录列表
     */
    List<Progress> findByUserId(Long userId);
} 