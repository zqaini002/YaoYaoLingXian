package com.dreamplanner.service;

import com.dreamplanner.dto.DreamDTO;
import com.dreamplanner.dto.DreamStatsDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

/**
 * 梦想服务接口
 *
 * @author DreamPlanner
 */
public interface DreamService {

    /**
     * 根据梦想ID获取梦想
     *
     * @param id 梦想ID
     * @return 梦想DTO
     */
    DreamDTO getDreamById(Long id);

    /**
     * 根据用户ID获取梦想列表
     *
     * @param userId 用户ID
     * @return 梦想DTO列表
     */
    List<DreamDTO> getDreamsByUserId(Long userId);

    /**
     * 分页获取用户的梦想列表
     *
     * @param userId   用户ID
     * @param pageable 分页参数
     * @return 梦想DTO分页列表
     */
    Page<DreamDTO> getDreamsByUserIdPageable(Long userId, Pageable pageable);

    /**
     * 根据用户ID和分类获取梦想列表
     *
     * @param userId   用户ID
     * @param category 分类
     * @return 梦想DTO列表
     */
    List<DreamDTO> getDreamsByUserIdAndCategory(Long userId, String category);

    /**
     * 根据用户ID和状态获取梦想列表
     *
     * @param userId 用户ID
     * @param status 状态
     * @return 梦想DTO列表
     */
    List<DreamDTO> getDreamsByUserIdAndStatus(Long userId, Integer status);

    /**
     * 获取用户梦想统计信息
     *
     * @param userId 用户ID
     * @return 梦想统计DTO
     */
    DreamStatsDTO getUserDreamStats(Long userId);

    /**
     * 创建梦想
     *
     * @param dreamDTO 梦想DTO
     * @return 创建的梦想DTO
     */
    DreamDTO createDream(DreamDTO dreamDTO);

    /**
     * 更新梦想
     *
     * @param id       梦想ID
     * @param dreamDTO 梦想DTO
     * @return 更新后的梦想DTO
     */
    DreamDTO updateDream(Long id, DreamDTO dreamDTO);

    /**
     * 删除梦想
     *
     * @param id 梦想ID
     */
    void deleteDream(Long id);

    /**
     * 获取公开的梦想列表
     *
     * @param pageable 分页参数
     * @return 公开梦想DTO分页列表
     */
    Page<DreamDTO> getPublicDreams(Pageable pageable);

    /**
     * 搜索梦想
     *
     * @param userId   用户ID
     * @param keyword  关键词
     * @param pageable 分页参数
     * @return 梦想DTO分页列表
     */
    Page<DreamDTO> searchDreams(Long userId, String keyword, Pageable pageable);

    /**
     * 检查梦想是否属于用户
     *
     * @param userId  用户ID
     * @param dreamId 梦想ID
     * @return 是否属于该用户
     */
    boolean isDreamOwner(Long userId, Long dreamId);
} 