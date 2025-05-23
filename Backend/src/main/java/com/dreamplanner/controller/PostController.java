package com.dreamplanner.controller;

import com.dreamplanner.common.ApiResponse;
import com.dreamplanner.entity.Post;
import com.dreamplanner.entity.User;
import com.dreamplanner.service.PostService;
import com.dreamplanner.service.UserService;
import com.dreamplanner.vo.PostVO;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 社区帖子控制器
 * 处理与社区帖子相关的请求
 */
@RestController
@RequestMapping("/posts")
@Slf4j
public class PostController {

    @Autowired
    private PostService postService;

    @Autowired
    private UserService userService;

    @PostConstruct
    public void init() {
        log.info("PostController初始化成功，API路径: /posts");
    }

    /**
     * 创建新帖子
     *
     * @param post 帖子信息
     * @return 操作结果
     */
    @PostMapping
    public ApiResponse createPost(@RequestBody Post post) {
        try {
            // 验证用户ID是否存在
            if (post.getUser() != null && post.getUser().getId() != null) {
                User user = userService.getUserById(post.getUser().getId()).toUser();
                if (user == null) {
                    return ApiResponse.error("用户不存在");
                }
            } else {
                return ApiResponse.error("用户ID不能为空");
            }

            Post savedPost = postService.createPost(post);
            log.info("创建帖子成功：{}", savedPost);
            return ApiResponse.success(savedPost);
        } catch (Exception e) {
            log.error("创建帖子失败", e);
            return ApiResponse.error("创建帖子失败：" + e.getMessage());
        }
    }

    /**
     * 获取帖子详情
     *
     * @param postId 帖子ID
     * @return 帖子详情
     */
    @GetMapping("/{postId}")
    public ApiResponse getPostDetail(@PathVariable Long postId) {
        try {
            PostVO post = postService.getPostVOById(postId);
            if (post == null) {
                return ApiResponse.error("帖子不存在");
            }
            return ApiResponse.success(post);
        } catch (Exception e) {
            log.error("获取帖子详情失败", e);
            return ApiResponse.error("获取帖子详情失败：" + e.getMessage());
        }
    }

    /**
     * 获取帖子列表（分页）
     *
     * @param page     页码(从0开始)
     * @param pageSize 每页数量
     * @param category 类别（可选）
     * @param userId   用户ID（可选，用于获取指定用户的帖子）
     * @return 帖子列表
     */
    @GetMapping
    public ApiResponse getPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Long userId) {

        try {
            log.info("获取帖子列表请求接收：page={}, pageSize={}, category={}, userId={}", page, pageSize, category, userId);

            Map<String, Object> result = postService.getPosts(page, pageSize, category, userId);
            return ApiResponse.success(result);
        } catch (Exception e) {
            log.error("获取帖子列表失败", e);
            return ApiResponse.error("获取帖子列表失败：" + e.getMessage());
        }
    }

    /**
     * 更新帖子
     *
     * @param postId 帖子ID
     * @param post   更新后的帖子信息
     * @return 操作结果
     */
    @PutMapping("/{postId}")
    public ApiResponse updatePost(@PathVariable Long postId, @RequestBody Post post) {
        try {
            // 验证帖子是否存在
            PostVO existingPost = postService.getPostVOById(postId);
            if (existingPost == null) {
                return ApiResponse.error("帖子不存在");
            }

            post.setId(postId);
            Post updatedPost = postService.updatePost(post);
            log.info("更新帖子成功：{}", updatedPost);
            return ApiResponse.success(updatedPost);
        } catch (Exception e) {
            log.error("更新帖子失败", e);
            return ApiResponse.error("更新帖子失败：" + e.getMessage());
        }
    }

    /**
     * 删除帖子
     *
     * @param postId 帖子ID
     * @return 操作结果
     */
    @DeleteMapping("/{postId}")
    public ApiResponse deletePost(@PathVariable Long postId) {
        try {
            // 验证帖子是否存在
            PostVO existingPost = postService.getPostVOById(postId);
            if (existingPost == null) {
                return ApiResponse.error("帖子不存在");
            }

            postService.deletePost(postId);
            log.info("删除帖子成功，ID：{}", postId);
            return ApiResponse.success("删除成功");
        } catch (Exception e) {
            log.error("删除帖子失败", e);
            return ApiResponse.error("删除帖子失败：" + e.getMessage());
        }
    }

    /**
     * 点赞/取消点赞帖子
     *
     * @param postId 帖子ID
     * @param userId 用户ID
     * @return 操作结果
     */
    @PostMapping("/{postId}/like")
    public ApiResponse likePost(@PathVariable Long postId, @RequestParam Long userId) {
        try {
            // 验证用户和帖子是否存在
            User user = userService.getUserById(userId).toUser();
            if (user == null) {
                return ApiResponse.error("用户不存在");
            }

            PostVO existingPost = postService.getPostVOById(postId);
            if (existingPost == null) {
                return ApiResponse.error("帖子不存在");
            }

            boolean isLiked = postService.toggleLike(postId, userId);
            Map<String, Object> result = new HashMap<>();
            result.put("liked", isLiked);

            log.info("用户{}{}帖子{}成功", userId, isLiked ? "点赞" : "取消点赞", postId);
            return ApiResponse.success(result);
        } catch (Exception e) {
            log.error("点赞操作失败", e);
            return ApiResponse.error("点赞操作失败：" + e.getMessage());
        }
    }

    /**
     * 获取帖子评论
     *
     * @param postId 帖子ID
     * @param page 页码
     * @param size 每页条数
     * @return 评论列表
     */
    @GetMapping("/{postId}/comments")
    public ApiResponse getPostComments(
            @PathVariable Long postId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            log.info("获取帖子评论请求: postId={}, page={}, size={}", postId, page, size);
            
            // 验证帖子是否存在
            PostVO existingPost = postService.getPostVOById(postId);
            if (existingPost == null) {
                return ApiResponse.error("帖子不存在");
            }
            
            List<?> comments = postService.getPostComments(
                postId, 
                PageRequest.of(page, size)
            );
            
            log.info("获取帖子评论成功，共返回{}条评论", comments.size());
            return ApiResponse.success(comments);
        } catch (Exception e) {
            log.error("获取帖子评论失败", e);
            return ApiResponse.error("获取帖子评论失败：" + e.getMessage());
        }
    }
    
    /**
     * 创建评论
     *
     * @param postId 帖子ID
     * @param comment 评论内容
     * @return 创建的评论
     */
    @PostMapping("/{postId}/comments")
    public ApiResponse createComment(
            @PathVariable Long postId,
            @RequestBody com.dreamplanner.dto.CommentDTO comment) {
        try {
            log.info("创建评论请求: postId={}, comment={}", postId, comment);
            
            // 获取当前认证用户
            org.springframework.security.core.Authentication authentication = 
                org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            
            if (authentication != null) {
                log.info("认证信息: principal={}, authenticated={}", 
                    authentication.getPrincipal(),
                    authentication.isAuthenticated());
                
                // 如果认证无效或是匿名用户
                if ("anonymousUser".equals(authentication.getPrincipal())) {
                    log.info("检测到匿名用户 - 使用commentDTO中的userId={}", comment.getUserId());
                    
                    // 确保commentDTO中有userId
                    if (comment.getUserId() == null) {
                        log.error("创建评论失败: 既无认证又无userId");
                        return ApiResponse.error("请先登录后再评论");
                    }
                } else {
                    // 获取用户详情，设置到CommentDTO中
                    org.springframework.security.core.userdetails.UserDetails userDetails = 
                        (org.springframework.security.core.userdetails.UserDetails) authentication.getPrincipal();
                    log.info("认证用户名: {}", userDetails.getUsername());
                    
                    // 无需设置userId，后端服务会处理
                }
            } else {
                log.error("创建评论失败: 无认证信息");
                return ApiResponse.error("请先登录后再评论");
            }
            
            // 验证帖子是否存在
            PostVO existingPost = postService.getPostVOById(postId);
            if (existingPost == null) {
                return ApiResponse.error("帖子不存在");
            }
            
            // 创建评论
            Object newComment = postService.commentPost(postId, comment);
            
            log.info("创建评论成功");
            return ApiResponse.success(newComment);
        } catch (Exception e) {
            log.error("创建评论失败", e);
            return ApiResponse.error("创建评论失败：" + e.getMessage());
        }
    }
} 