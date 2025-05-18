package com.dreamplanner.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 评论数据传输对象
 *
 * @author DreamPlanner
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommentDTO {
    private Long id;
    private Long postId;
    private Long userId;
    private String username;
    private String userAvatar;
    private String content;
    private Long parentId;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // 附加信息
    private Integer likeCount;
    private boolean isLiked;
    private List<CommentDTO> replies;
} 