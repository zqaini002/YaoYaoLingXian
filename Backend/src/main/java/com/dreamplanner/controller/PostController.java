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
            
            // 创建简化的返回对象，避免循环引用
            Map<String, Object> response = new HashMap<>();
            response.put("id", savedPost.getId());
            response.put("title", savedPost.getTitle());
            response.put("content", savedPost.getContent());
            response.put("images", savedPost.getImages());
            response.put("status", savedPost.getStatus());
            response.put("viewCount", savedPost.getViewCount());
            response.put("likeCount", savedPost.getLikeCount());
            response.put("commentCount", savedPost.getCommentCount());
            response.put("createdAt", savedPost.getCreatedAt());
            response.put("updatedAt", savedPost.getUpdatedAt());
            
            // 添加必要的关联ID
            if (savedPost.getUser() != null) {
                response.put("userId", savedPost.getUser().getId());
            }
            
            if (savedPost.getDream() != null) {
                response.put("dreamId", savedPost.getDream().getId());
            }
            
            log.info("创建帖子成功：{}", savedPost.getId());
            return ApiResponse.success(response);
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
     * @param authorId 用户ID（可选，用于获取指定用户的帖子）
     * @param currentUserId 当前用户ID（可选，用于处理点赞和关注状态）
     * @return 帖子列表
     */
    @GetMapping
    public ApiResponse getPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Long authorId,
            @RequestParam(required = false) Long currentUserId) {

        try {
            log.info("获取帖子列表请求接收：page={}, pageSize={}, category={}, authorId={}, currentUserId={}", 
                    page, pageSize, category, authorId, currentUserId);

            Map<String, Object> result = postService.getPosts(page, pageSize, category, authorId, currentUserId);
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
            
            // 获取当前认证用户
            org.springframework.security.core.Authentication authentication = 
                org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            
            // 如果有有效的认证信息，获取用户并设置到post对象中
            if (authentication != null && authentication.isAuthenticated() && 
                !"anonymousUser".equals(authentication.getPrincipal())) {
                String username = authentication.getName();
                User user = userService.getUserByUsername(username).toUser();
                if (user != null) {
                    post.setUser(user);
                    log.info("已将认证用户 ID={} 设置到更新的帖子中", user.getId());
                }
            } else {
                // 如果没有认证信息，检查是否传入了userId
                if (post.getUser() == null || post.getUser().getId() == null) {
                    log.info("未提供有效的user信息，将依赖后端service从原始帖子获取");
                }
            }
            
            // 确保status不为null
            if (post.getStatus() == null) {
                post.setStatus(1); // 默认设置为正常状态
                log.info("在控制器中设置默认status=1，确保不会出现null值错误");
            }
            
            Post updatedPost = postService.updatePost(post);
            log.info("更新帖子成功：{}", updatedPost);
            
            // 创建简化的返回对象，仅包含必要字段
            Map<String, Object> response = new HashMap<>();
            response.put("id", updatedPost.getId());
            response.put("title", updatedPost.getTitle());
            response.put("content", updatedPost.getContent());
            response.put("images", updatedPost.getImages());
            response.put("status", updatedPost.getStatus());
            response.put("viewCount", updatedPost.getViewCount());
            response.put("likeCount", updatedPost.getLikeCount());
            response.put("commentCount", updatedPost.getCommentCount());
            response.put("createdAt", updatedPost.getCreatedAt());
            response.put("updatedAt", updatedPost.getUpdatedAt());
            
            // 添加必要的关联ID
            if (updatedPost.getUser() != null) {
                response.put("userId", updatedPost.getUser().getId());
            }
            
            if (updatedPost.getDream() != null) {
                response.put("dreamId", updatedPost.getDream().getId());
            }
            
            return ApiResponse.success(response);
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
     * @param userId 用户ID（可选，如果未提供则从当前认证信息中获取）
     * @return 操作结果
     */
    @PostMapping("/{postId}/like")
    public ApiResponse likePost(@PathVariable Long postId, @RequestParam(required = false) Long userId) {
        try {
            Long effectiveUserId = userId;
            
            // 如果未提供userId，则从当前认证信息中获取
            if (effectiveUserId == null) {
                org.springframework.security.core.Authentication authentication = 
                    org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
                
                if (authentication != null && authentication.isAuthenticated() && 
                    !"anonymousUser".equals(authentication.getPrincipal())) {
                    String username = authentication.getName();
                    User authenticatedUser = userService.getUserByUsername(username).toUser();
                    if (authenticatedUser != null) {
                        effectiveUserId = authenticatedUser.getId();
                        log.info("从认证信息中获取用户ID: {}", effectiveUserId);
                    }
                }
            }
            
            // 确保有有效的用户ID
            if (effectiveUserId == null) {
                return ApiResponse.error("未提供用户ID且用户未登录");
            }
            
            // 验证用户和帖子是否存在
            User user = userService.getUserById(effectiveUserId).toUser();
            if (user == null) {
                return ApiResponse.error("用户不存在");
            }

            PostVO existingPost = postService.getPostVOById(postId);
            if (existingPost == null) {
                return ApiResponse.error("帖子不存在");
            }

            boolean isLiked = postService.toggleLike(postId, effectiveUserId);
            Map<String, Object> result = new HashMap<>();
            result.put("liked", isLiked);

            log.info("用户{}{}帖子{}成功", effectiveUserId, isLiked ? "点赞" : "取消点赞", postId);
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

    /**
     * 取消点赞帖子
     *
     * @param postId 帖子ID
     * @param userId 用户ID（可选，如果未提供则从当前认证信息中获取）
     * @return 操作结果
     */
    @DeleteMapping("/{postId}/like")
    public ApiResponse unlikePost(@PathVariable Long postId, @RequestParam(required = false) Long userId) {
        try {
            Long effectiveUserId = userId;
            
            // 如果未提供userId，则从当前认证信息中获取
            if (effectiveUserId == null) {
                org.springframework.security.core.Authentication authentication = 
                    org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
                
                if (authentication != null && authentication.isAuthenticated() && 
                    !"anonymousUser".equals(authentication.getPrincipal())) {
                    String username = authentication.getName();
                    User authenticatedUser = userService.getUserByUsername(username).toUser();
                    if (authenticatedUser != null) {
                        effectiveUserId = authenticatedUser.getId();
                        log.info("从认证信息中获取用户ID: {}", effectiveUserId);
                    }
                }
            }
            
            // 确保有有效的用户ID
            if (effectiveUserId == null) {
                return ApiResponse.error("未提供用户ID且用户未登录");
            }
            
            // 验证用户和帖子是否存在
            User user = userService.getUserById(effectiveUserId).toUser();
            if (user == null) {
                return ApiResponse.error("用户不存在");
            }

            PostVO existingPost = postService.getPostVOById(postId);
            if (existingPost == null) {
                return ApiResponse.error("帖子不存在");
            }

            // 直接调用toggleLike方法，它会检查是否已点赞并执行相应操作
            boolean isLiked = postService.toggleLike(postId, effectiveUserId);
            Map<String, Object> result = new HashMap<>();
            result.put("liked", isLiked);

            log.info("用户{}{}帖子{}成功", effectiveUserId, isLiked ? "点赞" : "取消点赞", postId);
            return ApiResponse.success(result);
        } catch (Exception e) {
            log.error("取消点赞操作失败", e);
            return ApiResponse.error("取消点赞操作失败：" + e.getMessage());
        }
    }
} 