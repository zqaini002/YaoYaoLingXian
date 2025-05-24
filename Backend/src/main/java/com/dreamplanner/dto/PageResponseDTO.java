package com.dreamplanner.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 分页响应数据传输对象
 * 与前端PageResponse接口对应
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PageResponseDTO<T> {

    /**
     * 内容列表
     */
    private List<T> content;

    /**
     * 总元素数
     */
    private long totalElements;

    /**
     * 总页数
     */
    private int totalPages;

    /**
     * 每页大小
     */
    private int size;

    /**
     * 当前页码（从0开始）
     */
    private int number;

    /**
     * 是否为第一页
     */
    private boolean first;

    /**
     * 是否为最后一页
     */
    private boolean last;
} 