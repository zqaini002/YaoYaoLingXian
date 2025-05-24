package com.dreamplanner.service;

import com.dreamplanner.dto.HomePageDTO;

/**
 * 首页服务接口
 * 提供首页所需的聚合数据
 *
 * @author DreamPlanner
 */
public interface HomeService {

    /**
     * 获取首页数据
     *
     * @param userId 用户ID
     * @return 首页数据DTO
     */
    HomePageDTO getHomePageData(Long userId);
} 