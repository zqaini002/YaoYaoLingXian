package com.dreamplanner.service.impl;

import com.dreamplanner.dto.CommentDTO;
import com.dreamplanner.dto.PostDTO;
import com.dreamplanner.entity.*;
import com.dreamplanner.exception.ResourceNotFoundException;
import com.dreamplanner.repository.CommentRepository;
import com.dreamplanner.repository.DreamRepository;
import com.dreamplanner.repository.LikeRepository;
import com.dreamplanner.repository.PostRepository;
import com.dreamplanner.repository.UserRepository;
import com.dreamplanner.service.PostService;
import com.dreamplanner.vo.PostVO;
import com.dreamplanner.vo.UserVO;
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
        
        // 添加请求参数查询功能
        Long requestParamUserId = null;
        try {
            // 尝试从请求参数中获取userId
            jakarta.servlet.http.HttpServletRequest request = 
                ((org.springframework.web.context.request.ServletRequestAttributes) 
                    org.springframework.web.context.request.RequestContextHolder.getRequestAttributes()).getRequest();
            
            String userIdParam = request.getParameter("userId");
            if (userIdParam != null && !userIdParam.isEmpty()) {
                requestParamUserId = Long.parseLong(userIdParam);
                log.info("从请求参数中获取到userId: {}", requestParamUserId);
            }
        } catch (Exception e) {
            log.warn("从请求参数获取userId失败", e);
        }
        
        // 如果SecurityContext中没有用户，但请求参数中有userId，则尝试从数据库获取用户
        if (currentUser == null && requestParamUserId != null) {
            currentUser = userRepository.findById(requestParamUserId).orElse(null);
            log.info("通过请求参数userId={}查找到用户: {}", requestParamUserId, 
                   currentUser != null ? currentUser.getUsername() : "未找到");
        }
        
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
        
        log.info("用户[{}]成功删除动态，ID: {}", currentUser.getUsername(), id);
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
        // 1. 尝试从SecurityContext获取当前用户
        User currentUser = getCurrentUser();
        log.info("评论帖子 - 从SecurityContext获取用户: {}", currentUser != null ? currentUser.getUsername() : "未找到");

        // 2. 如果SecurityContext中没有用户，尝试从评论DTO中获取userId
        if (currentUser == null && commentDTO.getUserId() != null) {
            log.info("尝试通过评论中的userId={}查找用户", commentDTO.getUserId());
            currentUser = userRepository.findById(commentDTO.getUserId())
                .orElse(null);
            log.info("通过userId查找结果: {}", currentUser != null ? "找到用户" : "未找到用户");
        }
        
        // 3. 如果仍然找不到用户，则抛出异常
        if (currentUser == null) {
            log.error("评论失败: 无法确认用户身份");
            throw new IllegalStateException("用户未登录");
        }
        
        // 4. 获取帖子
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("帖子不存在，ID: " + id));
        
        // 5. 创建评论
        Comment comment = new Comment();
        comment.setPost(post);
        comment.setUser(currentUser);
        comment.setContent(commentDTO.getContent());
        comment.setParentId(commentDTO.getParentId());
        comment.setStatus(1);
        comment.setCreatedAt(LocalDateTime.now());
        comment.setUpdatedAt(LocalDateTime.now());
        
        // 6. 保存评论
        Comment savedComment = commentRepository.save(comment);
        log.info("评论保存成功, ID: {}", savedComment.getId());
        
        // 7. 更新帖子评论数
        post.setCommentCount(post.getCommentCount() + 1);
        postRepository.save(post);
        log.info("更新帖子评论数成功, 当前评论数: {}", post.getCommentCount());
        
        // 8. 返回评论DTO
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
        
        // 设置用户和作者信息
        if (post.getUser() != null) {
            User author = post.getUser();
            postVO.setUserId(author.getId());
            postVO.setUsername(author.getUsername());
            postVO.setNickname(author.getNickname() != null ? author.getNickname() : author.getUsername());
            postVO.setUserAvatar(author.getAvatar());
            
            // 明确设置author对象，以便客户端能正确显示作者信息
            UserVO authorVO = new UserVO();
            authorVO.setId(author.getId());
            authorVO.setUsername(author.getUsername());
            authorVO.setNickname(author.getNickname() != null ? author.getNickname() : author.getUsername());
            authorVO.setAvatar(author.getAvatar());
            
            // 检查当前用户是否已关注帖子作者
            User currentUser = getCurrentUser();
            if (currentUser != null && !currentUser.getId().equals(author.getId())) {
                boolean isFollowing = false;
                // 检查当前用户的关注列表
                for (Follow follow : currentUser.getFollowing()) {
                    if (follow.getFollowed().getId().equals(author.getId())) {
                        isFollowing = true;
                        break;
                    }
                }
                authorVO.setIsFollowed(isFollowing);
            } else {
                authorVO.setIsFollowed(false);
            }
            
            postVO.setAuthor(authorVO);
        } else {
            // 如果用户为空，提供默认值
            log.warn("帖子 {} 缺少用户信息，使用默认值", post.getId());
            postVO.setUserId(0L);
            postVO.setUsername("未知用户");
            postVO.setNickname("未知用户");
            postVO.setUserAvatar("");
            
            UserVO defaultAuthor = new UserVO();
            defaultAuthor.setId(0L);
            defaultAuthor.setUsername("未知用户");
            defaultAuthor.setNickname("未知用户");
            defaultAuthor.setAvatar("");
            defaultAuthor.setIsFollowed(false);
            postVO.setAuthor(defaultAuthor);
        }
        
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
        } else {
            postVO.setLiked(false);
        }
        
        return postVO;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Object> getPosts(int page, int pageSize, String category, Long authorId, Long currentUserId) {
        // 添加日志记录
        log.info("PostServiceImpl.getPosts方法被调用：page={}, pageSize={}, category={}, authorId={}, currentUserId={}", 
                page, pageSize, category, authorId, currentUserId);
        
        // 创建分页请求
        Pageable pageable = PageRequest.of(page, pageSize, Sort.by(Sort.Direction.DESC, "createdAt"));
        
        Page<Post> postPage;
        
        // 根据条件查询帖子
        if (authorId != null) {
            // 查询特定用户的帖子
            User user = userRepository.findById(authorId)
                    .orElseThrow(() -> new ResourceNotFoundException("用户不存在，ID: " + authorId));
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
                User currentUser = null;
                
                // 如果提供了currentUserId，根据它获取用户
                if (currentUserId != null) {
                    currentUser = userRepository.findById(currentUserId).orElse(null);
                }
                
                // 如果没有提供currentUserId或找不到用户，尝试从安全上下文获取
                if (currentUser == null) {
                    currentUser = getCurrentUser();
                }
                
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
        
        // 获取用于检查点赞和关注状态的用户
        User statusCheckUser = null;
        
        // 如果提供了currentUserId，根据它获取用户
        if (currentUserId != null) {
            statusCheckUser = userRepository.findById(currentUserId).orElse(null);
        }
        
        // 如果没有提供currentUserId或找不到用户，尝试从安全上下文获取
        if (statusCheckUser == null) {
            statusCheckUser = getCurrentUser();
        }
        
        // 最终用于检查状态的用户引用
        final User finalStatusCheckUser = statusCheckUser;
        
        // 转换为视图对象
        List<PostVO> postVOs = postPage.getContent().stream()
                .map(post -> {
                    PostVO vo = new PostVO();
                    vo.setId(post.getId());
                    
                    // 确保用户信息正确获取和设置
                    if (post.getUser() != null) {
                        User postAuthor = post.getUser();
                        vo.setUserId(postAuthor.getId());
                        vo.setUsername(postAuthor.getUsername());
                        vo.setNickname(postAuthor.getNickname() != null ? postAuthor.getNickname() : postAuthor.getUsername());
                        vo.setUserAvatar(postAuthor.getAvatar());
                        
                        // 设置作者信息
                        UserVO authorVO = new UserVO();
                        authorVO.setId(postAuthor.getId());
                        authorVO.setUsername(postAuthor.getUsername());
                        authorVO.setNickname(postAuthor.getNickname() != null ? postAuthor.getNickname() : postAuthor.getUsername());
                        authorVO.setAvatar(postAuthor.getAvatar());
                        authorVO.setIsFollowed(false); // 默认未关注
                        
                        vo.setAuthor(authorVO);
                        
                        // 如果提供了当前用户，检查是否已关注作者
                        if (finalStatusCheckUser != null && finalStatusCheckUser.getId() != null && 
                            !finalStatusCheckUser.getId().equals(postAuthor.getId())) {
                            // 检查当前用户是否关注了帖子作者
                            boolean isFollowing = finalStatusCheckUser.getFollowing().stream()
                                .anyMatch(follow -> follow.getFollowed().getId().equals(postAuthor.getId()));
                            vo.getAuthor().setIsFollowed(isFollowing);
                        }
                    } else {
                        // 如果用户为空，设置默认值
                        log.warn("帖子 {} 缺少用户信息，使用默认值", post.getId());
                        vo.setUserId(0L);
                        vo.setUsername("未知用户");
                        vo.setNickname("未知用户");
                        vo.setUserAvatar("");
                        
                        // 设置默认作者信息
                        UserVO authorVO = new UserVO();
                        authorVO.setId(0L);
                        authorVO.setUsername("未知用户");
                        authorVO.setNickname("未知用户");
                        authorVO.setAvatar("");
                        authorVO.setIsFollowed(false);
                        
                        vo.setAuthor(authorVO);
                    }
                    
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
                    if (finalStatusCheckUser != null) {
                        vo.setLiked(likeRepository.findByPostAndUser(post, finalStatusCheckUser).isPresent());
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
        // 获取原始帖子，确保必要字段不会被覆盖
        Post originalPost = postRepository.findById(post.getId())
                .orElseThrow(() -> new ResourceNotFoundException("帖子不存在，ID: " + post.getId()));
        
        // 最重要：确保user不为null，保留原始的user对象
        if (post.getUser() == null) {
            post.setUser(originalPost.getUser());
            log.info("帖子更新时user为null，使用原始user: userId={}", 
                originalPost.getUser() != null ? originalPost.getUser().getId() : "null");
        } else {
            log.info("帖子更新使用提供的user: userId={}", post.getUser().getId());
        }
        
        // 再次确认user对象已正确设置
        if (post.getUser() == null) {
            log.error("严重错误：更新帖子时user仍为null，这将导致数据库错误");
            throw new IllegalArgumentException("更新帖子失败：用户信息缺失");
        }
        
        // 确保status不为null，如果客户端未提供，使用原始状态
        if (post.getStatus() == null) {
            post.setStatus(originalPost.getStatus());
            log.info("帖子更新时status为null，使用原值: {}", originalPost.getStatus());
        } else {
            log.info("帖子更新使用提供的status: {}", post.getStatus());
        }
        
        // 确保其他必要字段不为null
        if (post.getViewCount() == null) {
            post.setViewCount(originalPost.getViewCount());
            log.info("帖子更新时viewCount为null，使用原值: {}", originalPost.getViewCount());
        }
        
        if (post.getLikeCount() == null) {
            post.setLikeCount(originalPost.getLikeCount());
            log.info("帖子更新时likeCount为null，使用原值: {}", originalPost.getLikeCount());
        }
        
        if (post.getCommentCount() == null) {
            post.setCommentCount(originalPost.getCommentCount());
            log.info("帖子更新时commentCount为null，使用原值: {}", originalPost.getCommentCount());
        }
        
        // 保留原始关系数据
        post.setComments(originalPost.getComments());
        post.setLikes(originalPost.getLikes());
        
        log.info("更新帖子完整信息 - ID: {}, 标题: {}, 状态: {}, 用户ID: {}, 内容长度: {}", 
                post.getId(), post.getTitle(), post.getStatus(), 
                post.getUser().getId(), 
                post.getContent() != null ? post.getContent().length() : 0);
                
        // 保存更新的帖子
        Post savedPost = postRepository.save(post);
        log.info("帖子更新成功，ID: {}", savedPost.getId());
        
        // 返回简化版的Post对象，避免无限递归序列化问题
        Post simplifiedPost = new Post();
        simplifiedPost.setId(savedPost.getId());
        simplifiedPost.setTitle(savedPost.getTitle());
        simplifiedPost.setContent(savedPost.getContent());
        simplifiedPost.setImages(savedPost.getImages());
        simplifiedPost.setStatus(savedPost.getStatus());
        simplifiedPost.setViewCount(savedPost.getViewCount());
        simplifiedPost.setLikeCount(savedPost.getLikeCount());
        simplifiedPost.setCommentCount(savedPost.getCommentCount());
        simplifiedPost.setCreatedAt(savedPost.getCreatedAt());
        simplifiedPost.setUpdatedAt(savedPost.getUpdatedAt());
        
        // 不设置双向关联，避免循环引用
        // simplifiedPost.setUser(savedPost.getUser());
        // simplifiedPost.setDream(savedPost.getDream());
        // simplifiedPost.setComments(savedPost.getComments());
        // simplifiedPost.setLikes(savedPost.getLikes());
        
        return simplifiedPost;
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