package com.dreamplanner.service.impl;

import com.dreamplanner.dto.CommentDTO;
import com.dreamplanner.dto.PostDTO;
import com.dreamplanner.entity.Comment;
import com.dreamplanner.entity.Dream;
import com.dreamplanner.entity.Like;
import com.dreamplanner.entity.Post;
import com.dreamplanner.entity.User;
import com.dreamplanner.exception.ResourceNotFoundException;
import com.dreamplanner.repository.CommentRepository;
import com.dreamplanner.repository.DreamRepository;
import com.dreamplanner.repository.LikeRepository;
import com.dreamplanner.repository.PostRepository;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.PostService;
import com.dreamplanner.vo.PostVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 社区动态服务实现类
 *
 * @author DreamPlanner
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PostServiceImpl implements PostService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final DreamRepository dreamRepository;
    private final CommentRepository commentRepository;
    private final LikeRepository likeRepository;

    /**
     * 获取当前登录用户
     *
     * @return 当前用户对象，如果未登录则返回null
     */
    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getPrincipal())) {
            String username = authentication.getName();
            return userRepository.findByUsername(username).orElse(null);
        }
        return null;
    }

    /**
     * 将Post实体转换为DTO
     */
    private PostDTO convertToDTO(Post post) {
        User currentUser = getCurrentUser();
        boolean isLiked = false;
        
        // 检查当前用户是否点赞过该动态
        if (currentUser != null) {
            isLiked = likeRepository.findByPostAndUser(post, currentUser).isPresent();
        }
        
        // 处理图片URL
        List<String> images = new ArrayList<>();
        if (post.getImages() != null && !post.getImages().isEmpty()) {
            images = Arrays.asList(post.getImages().split(","));
        }
        
        return PostDTO.builder()
                .id(post.getId())
                .userId(post.getUser().getId())
                .username(post.getUser().getUsername())
                .userAvatar(post.getUser().getAvatar())
                .dreamId(post.getDream() != null ? post.getDream().getId() : null)
                .dreamTitle(post.getDream() != null ? post.getDream().getTitle() : null)
                .title(post.getTitle())
                .content(post.getContent())
                .images(images)
                .status(post.getStatus())
                .viewCount(post.getViewCount())
                .likeCount(post.getLikeCount())
                .commentCount(post.getCommentCount())
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .isLiked(isLiked)
                .build();
    }

    /**
     * 将Comment实体转换为DTO
     */
    private CommentDTO convertCommentToDTO(Comment comment) {
        User currentUser = getCurrentUser();
        boolean isLiked = false;
        
        // 检查当前用户是否点赞过该评论
        if (currentUser != null) {
            isLiked = likeRepository.findByCommentAndUser(comment, currentUser).isPresent();
        }
        
        CommentDTO dto = CommentDTO.builder()
                .id(comment.getId())
                .postId(comment.getPost().getId())
                .userId(comment.getUser().getId())
                .username(comment.getUser().getUsername())
                .userAvatar(comment.getUser().getAvatar())
                .content(comment.getContent())
                .parentId(comment.getParentId())
                .status(comment.getStatus())
                .createdAt(comment.getCreatedAt())
                .updatedAt(comment.getUpdatedAt())
                .likeCount(comment.getLikes() != null ? comment.getLikes().size() : 0)
                .isLiked(isLiked)
                .build();
        
        // 获取回复评论
        if (comment.getReplies() != null && !comment.getReplies().isEmpty()) {
            List<CommentDTO> replies = comment.getReplies().stream()
                    .filter(reply -> reply.getStatus() == 1)
                    .map(this::convertCommentToDTO)
                    .collect(Collectors.toList());
            dto.setReplies(replies);
        }
        
        return dto;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PostDTO> getRecommendedPosts(Pageable pageable) {
        Page<Post> posts = postRepository.findByStatusOrderByCreatedAtDesc(1, pageable);
        return posts.map(this::convertToDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PostDTO> getFollowingPosts(Pageable pageable) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            // 未登录用户返回推荐内容
            return getRecommendedPosts(pageable);
        }
        
        // 获取关注用户的ID列表
        List<Long> followingIds = currentUser.getFollowing().stream()
                .map(follow -> follow.getFollowed().getId())
                .collect(Collectors.toList());
        
        if (followingIds.isEmpty()) {
            // 如果没有关注任何用户，返回推荐内容
            return getRecommendedPosts(pageable);
        }
        
        Page<Post> posts = postRepository.findByUserIdInAndStatusOrderByCreatedAtDesc(followingIds, 1, pageable);
        return posts.map(this::convertToDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PostDTO> getHotPosts(Pageable pageable) {
        // 基于点赞数、评论数和浏览数综合排序
        Page<Post> posts = postRepository.findHotPosts(1, pageable);
        return posts.map(this::convertToDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public PostDTO getPostById(Long id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("动态不存在，ID: " + id));
        
        // 增加浏览次数
        post.setViewCount(post.getViewCount() + 1);
        postRepository.save(post);
        
        PostDTO postDTO = convertToDTO(post);
        
        // 获取评论列表(仅获取前5条一级评论)
        List<Comment> comments = commentRepository.findByPostAndParentIdIsNullAndStatusOrderByCreatedAtDesc(
                post, 1, PageRequest.of(0, 5));
                
        List<CommentDTO> commentDTOs = comments.stream()
                .map(this::convertCommentToDTO)
                .collect(Collectors.toList());
        
        postDTO.setComments(commentDTOs);
        
        return postDTO;
    }

    @Override
    @Transactional
    public PostDTO createPost(PostDTO postDTO) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            throw new IllegalStateException("用户未登录");
        }
        
        Post post = new Post();
        post.setUser(currentUser);
        post.setTitle(postDTO.getTitle());
        post.setContent(postDTO.getContent());
        
        // 处理关联的梦想
        if (postDTO.getDreamId() != null) {
            Dream dream = dreamRepository.findById(postDTO.getDreamId())
                    .orElseThrow(() -> new ResourceNotFoundException("梦想不存在，ID: " + postDTO.getDreamId()));
            post.setDream(dream);
        }
        
        // 处理图片
        if (postDTO.getImages() != null && !postDTO.getImages().isEmpty()) {
            post.setImages(String.join(",", postDTO.getImages()));
        }
        
        post.setStatus(1);
        post.setViewCount(0);
        post.setLikeCount(0);
        post.setCommentCount(0);
        
        Post savedPost = postRepository.save(post);
        return convertToDTO(savedPost);
    }

    @Override
    @Transactional
    public PostDTO updatePost(Long id, PostDTO postDTO) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            throw new IllegalStateException("用户未登录");
        }
        
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("动态不存在，ID: " + id));
        
        // 检查是否为动态作者
        if (!post.getUser().getId().equals(currentUser.getId())) {
            throw new IllegalStateException("只能更新自己发布的动态");
        }
        
        // 更新动态信息
        post.setTitle(postDTO.getTitle());
        post.setContent(postDTO.getContent());
        
        // 处理关联的梦想
        if (postDTO.getDreamId() != null) {
            Dream dream = dreamRepository.findById(postDTO.getDreamId())
                    .orElseThrow(() -> new ResourceNotFoundException("梦想不存在，ID: " + postDTO.getDreamId()));
            post.setDream(dream);
        } else {
            post.setDream(null);
        }
        
        // 处理图片
        if (postDTO.getImages() != null) {
            post.setImages(String.join(",", postDTO.getImages()));
        }
        
        Post updatedPost = postRepository.save(post);
        return convertToDTO(updatedPost);
    }

    @Override
    @Transactional
    public void deletePost(Long id) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            throw new IllegalStateException("用户未登录");
        }
        
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("动态不存在，ID: " + id));
        
        // 检查是否为动态作者
        if (!post.getUser().getId().equals(currentUser.getId())) {
            throw new IllegalStateException("只能删除自己发布的动态");
        }
        
        // 逻辑删除
        post.setStatus(0);
        postRepository.save(post);
    }

    @Override
    @Transactional
    public void likePost(Long id) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            throw new IllegalStateException("用户未登录");
        }
        
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("动态不存在，ID: " + id));
        
        // 检查是否已点赞
        Optional<Like> existingLike = likeRepository.findByPostAndUser(post, currentUser);
        if (existingLike.isPresent()) {
            // 已点赞，不做处理
            return;
        }
        
        // 创建点赞记录
        Like like = new Like();
        like.setPost(post);
        like.setUser(currentUser);
        like.setCreatedAt(LocalDateTime.now());
        likeRepository.save(like);
        
        // 更新动态点赞数
        post.setLikeCount(post.getLikeCount() + 1);
        postRepository.save(post);
    }

    @Override
    @Transactional
    public void unlikePost(Long id) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            throw new IllegalStateException("用户未登录");
        }
        
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("动态不存在，ID: " + id));
        
        // 检查是否已点赞
        Optional<Like> existingLike = likeRepository.findByPostAndUser(post, currentUser);
        if (!existingLike.isPresent()) {
            // 未点赞，不做处理
            return;
        }
        
        // 删除点赞记录
        likeRepository.delete(existingLike.get());
        
        // 更新动态点赞数
        post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
        postRepository.save(post);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CommentDTO> getPostComments(Long id, Pageable pageable) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("动态不存在，ID: " + id));
        
        // 获取一级评论（不包含回复的评论）
        List<Comment> comments = commentRepository.findByPostAndParentIsNullAndStatusOrderByCreatedAtDesc(
                post, 1, pageable);
                
        return comments.stream()
                .map(this::convertCommentToDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public CommentDTO commentPost(Long id, CommentDTO commentDTO) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            throw new IllegalStateException("用户未登录");
        }
        
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("动态不存在，ID: " + id));
        
        Comment comment = new Comment();
        comment.setPost(post);
        comment.setUser(currentUser);
        comment.setContent(commentDTO.getContent());
        comment.setStatus(1);
        
        // 处理回复的评论
        if (commentDTO.getParentId() != null) {
            Comment parentComment = commentRepository.findById(commentDTO.getParentId())
                    .orElseThrow(() -> new ResourceNotFoundException("回复的评论不存在，ID: " + commentDTO.getParentId()));
            comment.setParent(parentComment);
        }
        
        Comment savedComment = commentRepository.save(comment);
        
        // 更新动态评论数
        post.setCommentCount(post.getCommentCount() + 1);
        postRepository.save(post);
        
        return convertCommentToDTO(savedComment);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PostDTO> getUserPosts(Long userId, Pageable pageable) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在，ID: " + userId));
        
        Page<Post> posts = postRepository.findByUserAndStatusOrderByCreatedAtDesc(user, 1, pageable);
        return posts.map(this::convertToDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PostDTO> getDreamPosts(Long dreamId, Pageable pageable) {
        Dream dream = dreamRepository.findById(dreamId)
                .orElseThrow(() -> new ResourceNotFoundException("梦想不存在，ID: " + dreamId));
        
        Page<Post> posts = postRepository.findByDreamAndStatusOrderByCreatedAtDesc(dream, 1, pageable);
        return posts.map(this::convertToDTO);
    }

    @Override
    @Transactional
    public Post createPost(Post post) {
        return postRepository.save(post);
    }

    @Override
    @Transactional(readOnly = true)
    public PostVO getPostVOById(Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("帖子不存在，ID: " + postId));
        
        // 增加浏览次数
        post.setViewCount(post.getViewCount() + 1);
        postRepository.save(post);
        
        // 转换为 PostVO 对象并返回
        PostVO postVO = new PostVO();
        postVO.setId(post.getId());
        postVO.setUserId(post.getUser().getId());
        postVO.setUsername(post.getUser().getUsername());
        postVO.setUserAvatar(post.getUser().getAvatar());
        
        if (post.getDream() != null) {
            postVO.setDreamId(post.getDream().getId());
            postVO.setDreamTitle(post.getDream().getTitle());
        }
        
        postVO.setTitle(post.getTitle());
        postVO.setContent(post.getContent());
        
        // 处理图片URL
        if (post.getImages() != null && !post.getImages().isEmpty()) {
            postVO.setImages(Arrays.asList(post.getImages().split(",")));
        }
        
        postVO.setViewCount(post.getViewCount());
        postVO.setLikeCount(post.getLikeCount());
        postVO.setCommentCount(post.getCommentCount());
        postVO.setCreatedAt(post.getCreatedAt());
        postVO.setUpdatedAt(post.getUpdatedAt());
        
        // 检查当前用户是否点赞
        User currentUser = getCurrentUser();
        if (currentUser != null) {
            postVO.setLiked(likeRepository.findByPostAndUser(post, currentUser).isPresent());
        }
        
        return postVO;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Object> getPosts(int page, int pageSize, String category, Long userId) {
        // 添加日志记录
        log.info("PostServiceImpl.getPosts方法被调用：page={}, pageSize={}, category={}, userId={}", page, pageSize, category, userId);
        
        // 创建分页请求
        Pageable pageable = PageRequest.of(page, pageSize, Sort.by(Sort.Direction.DESC, "createdAt"));
        
        Page<Post> postPage;
        
        // 根据条件查询帖子
        if (userId != null) {
            // 查询特定用户的帖子
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("用户不存在，ID: " + userId));
            postPage = postRepository.findByUserAndStatus(user, 1, pageable);
        } else if (category != null && !category.isEmpty()) {
            // 根据前端传递的特殊分类进行查询
            log.info("根据category查询帖子: {}", category);
            if ("recommendation".equalsIgnoreCase(category)) {
                // 推荐内容
                postPage = postRepository.findByStatus(1, pageable);
                log.info("查询推荐内容，找到{}条记录", postPage.getTotalElements());
            } else if ("following".equalsIgnoreCase(category)) {
                // 关注内容 - 获取当前用户
                User currentUser = getCurrentUser();
                if (currentUser != null && !currentUser.getFollowing().isEmpty()) {
                    // 获取关注用户的ID列表
                    List<Long> followingIds = currentUser.getFollowing().stream()
                            .map(follow -> follow.getFollowed().getId())
                            .collect(Collectors.toList());
                    postPage = postRepository.findByUserIdInAndStatusOrderByCreatedAtDesc(followingIds, 1, pageable);
                    log.info("查询关注内容，找到{}条记录", postPage.getTotalElements());
                } else {
                    // 如果未登录或没有关注任何用户，返回推荐内容
                    postPage = postRepository.findByStatus(1, pageable);
                    log.info("用户未登录或没有关注任何人，返回推荐内容，找到{}条记录", postPage.getTotalElements());
                }
            } else if ("hot".equalsIgnoreCase(category)) {
                // 热门内容
                postPage = postRepository.findHotPosts(1, pageable);
                log.info("查询热门内容，找到{}条记录", postPage.getTotalElements());
            } else {
                // 其他分类按梦想分类查询
                postPage = postRepository.findByDreamCategoryAndStatus(category, 1, pageable);
                log.info("查询分类{}的内容，找到{}条记录", category, postPage.getTotalElements());
            }
        } else {
            // 查询所有帖子（默认推荐）
            postPage = postRepository.findByStatus(1, pageable);
            log.info("查询所有帖子（默认推荐），找到{}条记录", postPage.getTotalElements());
        }
        
        // 转换为视图对象
        List<PostVO> postVOs = postPage.getContent().stream()
                .map(post -> {
                    PostVO vo = new PostVO();
                    vo.setId(post.getId());
                    vo.setUserId(post.getUser().getId());
                    vo.setUsername(post.getUser().getUsername());
                    vo.setUserAvatar(post.getUser().getAvatar());
                    
                    if (post.getDream() != null) {
                        vo.setDreamId(post.getDream().getId());
                        vo.setDreamTitle(post.getDream().getTitle());
                    }
                    
                    vo.setTitle(post.getTitle());
                    vo.setContent(post.getContent());
                    
                    // 处理图片URL
                    if (post.getImages() != null && !post.getImages().isEmpty()) {
                        vo.setImages(Arrays.asList(post.getImages().split(",")));
                    }
                    
                    vo.setViewCount(post.getViewCount());
                    vo.setLikeCount(post.getLikeCount());
                    vo.setCommentCount(post.getCommentCount());
                    vo.setCreatedAt(post.getCreatedAt());
                    vo.setUpdatedAt(post.getUpdatedAt());
                    
                    // 检查当前用户是否点赞
                    User currentUser = getCurrentUser();
                    if (currentUser != null) {
                        vo.setLiked(likeRepository.findByPostAndUser(post, currentUser).isPresent());
                    }
                    
                    return vo;
                })
                .collect(Collectors.toList());
        
        // 构建返回结果
        Map<String, Object> result = new java.util.HashMap<>();
        result.put("posts", postVOs);
        result.put("currentPage", postPage.getNumber());
        result.put("totalItems", postPage.getTotalElements());
        result.put("totalPages", postPage.getTotalPages());
        
        log.info("返回帖子列表数据：{} 条记录", postVOs.size());
        return result;
    }

    @Override
    @Transactional
    public Post updatePost(Post post) {
        return postRepository.save(post);
    }

    @Override
    @Transactional
    public boolean toggleLike(Long postId, Long userId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("帖子不存在，ID: " + postId));
        
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在，ID: " + userId));
        
        // 检查是否已点赞
        Optional<Like> existingLike = likeRepository.findByPostAndUser(post, user);
        
        if (existingLike.isPresent()) {
            // 已点赞，取消点赞
            likeRepository.delete(existingLike.get());
            
            // 更新帖子点赞数
            post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
            postRepository.save(post);
            
            return false; // 返回当前状态：未点赞
        } else {
            // 未点赞，添加点赞
            Like like = new Like();
            like.setPost(post);
            like.setUser(user);
            like.setCreatedAt(LocalDateTime.now());
            likeRepository.save(like);
            
            // 更新帖子点赞数
            post.setLikeCount(post.getLikeCount() + 1);
            postRepository.save(post);
            
            return true; // 返回当前状态：已点赞
        }
    }
} 