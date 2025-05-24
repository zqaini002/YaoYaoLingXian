package com.dreamplanner.controller;

import com.dreamplanner.dto.HomePageDTO;
import com.dreamplanner.service.HomeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 首页控制器
 * 提供首页所需的聚合数据
 *
 * @author DreamPlanner
 */
@RestController
@RequestMapping("/home")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "首页", description = "首页相关接口")
public class HomeController {

    private final HomeService homeService;

    @GetMapping("/{userId}")
    @Operation(summary = "获取首页数据", description = "获取指定用户的首页综合数据")
    public ResponseEntity<HomePageDTO> getHomePageData(@PathVariable Long userId) {
        log.info("获取首页数据, userId: {}", userId);
        return ResponseEntity.ok(homeService.getHomePageData(userId));
    }
} 