package com.dreamplanner.dto;

import com.dreamplanner.entity.Post;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 帖子数据传输对象
 * 用于前端展示和数据传输的帖子信息
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PostDTO implements Serializable {
    
    private static final long serialVersionUID = 1L;

    /**
     * 帖子ID
     */
    private Long id;
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 用户名
     */
    private String username;
    
    /**
     * 用户头像
     */
    private String userAvatar;
    
    /**
     * 梦想ID
     */
    private Long dreamId;
    
    /**
     * 梦想标题
     */
    private String dreamTitle;
    
    /**
     * 帖子标题
     */
    private String title;
    
    /**
     * 帖子内容
     */
    private String content;
    
    /**
     * 帖子图片URL列表
     */
    private List<String> images;
    
    /**
     * 状态：0-删除，1-正常
     */
    private Integer status;
    
    /**
     * 浏览次数
     */
    private Integer viewCount;
    
    /**
     * 点赞次数
     */
    private Integer likeCount;
    
    /**
     * 评论次数
     */
    private Integer commentCount;
    
    /**
     * 当前用户是否点赞
     */
    private Boolean isLiked;
    
    /**
     * 评论列表
     */
    private List<CommentDTO> comments;
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
    
    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;
    
    /**
     * 从Post实体转换为PostDTO
     *
     * @param post Post实体
     * @return PostDTO对象
     */
    public static PostDTO fromPost(Post post) {
        if (post == null) {
            return null;
        }
        
        PostDTO postDTO = new PostDTO();
        postDTO.setId(post.getId());
        
        if (post.getUser() != null) {
            postDTO.setUserId(post.getUser().getId());
            postDTO.setUsername(post.getUser().getUsername());
            postDTO.setUserAvatar(post.getUser().getAvatar());
        }
        
        if (post.getDream() != null) {
            postDTO.setDreamId(post.getDream().getId());
            postDTO.setDreamTitle(post.getDream().getTitle());
        }
        
        postDTO.setTitle(post.getTitle());
        postDTO.setContent(post.getContent());
        
        // 处理图片字符串转换为列表
        if (post.getImages() != null && !post.getImages().isEmpty()) {
            String[] imageArray = post.getImages().split(",");
            postDTO.setImages(List.of(imageArray));
        }
        
        postDTO.setStatus(post.getStatus());
        postDTO.setViewCount(post.getViewCount());
        postDTO.setLikeCount(post.getLikeCount());
        postDTO.setCommentCount(post.getCommentCount());
        postDTO.setCreatedAt(post.getCreatedAt());
        postDTO.setUpdatedAt(post.getUpdatedAt());
        
        return postDTO;
    }
} 