package com.dreamplanner.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;

/**
 * 资源数据传输对象
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "资源信息")
public class ResourceDTO {

    @Schema(description = "资源ID")
    private Long id;

    @Schema(description = "资源标题")
    @NotBlank(message = "资源标题不能为空")
    private String title;

    @Schema(description = "资源描述")
    private String description;

    @Schema(description = "资源类型：课程、书籍、文章、视频等")
    private String type;

    @Schema(description = "资源分类")
    private String category;

    @Schema(description = "资源链接")
    private String url;

    @Schema(description = "图片URL")
    private String imageUrl;

    @Schema(description = "状态：0-下架，1-上架")
    private Integer status;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;
} 