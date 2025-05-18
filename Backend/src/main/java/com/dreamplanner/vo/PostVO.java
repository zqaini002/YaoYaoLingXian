package com.dreamplanner.vo;

import com.dreamplanner.entity.Post;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 帖子视图对象
 * 用于前端展示的帖子数据，包含了用户信息和点赞信息
 */
@Data
public class PostVO {
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
     * 浏览数
     */
    private Integer viewCount;
    
    /**
     * 点赞数
     */
    private Integer likeCount;
    
    /**
     * 评论数
     */
    private Integer commentCount;
    
    /**
     * 当前查看用户是否已点赞
     */
    private Boolean isLiked;
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
    
    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;
    
    /**
     * 从Post实体类转换为PostVO视图对象
     *
     * @param post Post实体
     * @return PostVO视图对象
     */
    public static PostVO fromPost(Post post) {
        if (post == null) {
            return null;
        }
        
        PostVO postVO = new PostVO();
        postVO.setId(post.getId());
        
        if (post.getUser() != null) {
            postVO.setUserId(post.getUser().getId());
            postVO.setUsername(post.getUser().getUsername());
            postVO.setUserAvatar(post.getUser().getAvatar());
        }
        
        if (post.getDream() != null) {
            postVO.setDreamId(post.getDream().getId());
            postVO.setDreamTitle(post.getDream().getTitle());
        }
        
        postVO.setTitle(post.getTitle());
        postVO.setContent(post.getContent());
        postVO.setViewCount(post.getViewCount());
        postVO.setLikeCount(post.getLikeCount());
        postVO.setCommentCount(post.getCommentCount());
        postVO.setCreatedAt(post.getCreatedAt());
        postVO.setUpdatedAt(post.getUpdatedAt());
        
        // 图片处理
        if (post.getImages() != null && !post.getImages().isEmpty()) {
            String[] imageArray = post.getImages().split(",");
            postVO.setImages(List.of(imageArray));
        }
        
        return postVO;
    }

    /**
     * 设置是否已点赞
     * 
     * @param isLiked 是否已点赞
     */
    public void setLiked(boolean isLiked) {
        this.isLiked = isLiked;
    }
} 