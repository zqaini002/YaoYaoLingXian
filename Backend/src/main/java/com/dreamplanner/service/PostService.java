package com.dreamplanner.service;

import com.dreamplanner.dto.CommentDTO;
import com.dreamplanner.dto.PostDTO;
import com.dreamplanner.entity.Post;
import com.dreamplanner.vo.PostVO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Map;

/**
 * 社区动态服务接口
 *
 * @author DreamPlanner
 */
public interface PostService {

    /**
     * 获取推荐动态列表
     *
     * @param pageable 分页参数
     * @return 动态分页数据
     */
    Page<PostDTO> getRecommendedPosts(Pageable pageable);

    /**
     * 获取关注用户的动态列表
     *
     * @param pageable 分页参数
     * @return 动态分页数据
     */
    Page<PostDTO> getFollowingPosts(Pageable pageable);

    /**
     * 获取热门动态列表
     *
     * @param pageable 分页参数
     * @return 动态分页数据
     */
    Page<PostDTO> getHotPosts(Pageable pageable);

    /**
     * 根据ID获取动态详情
     *
     * @param id 动态ID
     * @return 动态详情
     */
    PostDTO getPostById(Long id);

    /**
     * 创建新动态
     *
     * @param postDTO 动态信息
     * @return 创建后的动态
     */
    PostDTO createPost(PostDTO postDTO);

    /**
     * 更新动态
     *
     * @param id 动态ID
     * @param postDTO 更新信息
     * @return 更新后的动态
     */
    PostDTO updatePost(Long id, PostDTO postDTO);

    /**
     * 删除动态
     *
     * @param id 动态ID
     */
    void deletePost(Long id);

    /**
     * 点赞动态
     *
     * @param id 动态ID
     */
    void likePost(Long id);

    /**
     * 取消点赞
     *
     * @param id 动态ID
     */
    void unlikePost(Long id);

    /**
     * 获取动态评论
     *
     * @param id 动态ID
     * @param pageable 分页参数
     * @return 评论列表
     */
    List<CommentDTO> getPostComments(Long id, Pageable pageable);

    /**
     * 评论动态
     *
     * @param id 动态ID
     * @param commentDTO 评论信息
     * @return 创建后的评论
     */
    CommentDTO commentPost(Long id, CommentDTO commentDTO);

    /**
     * 获取用户的动态列表
     *
     * @param userId 用户ID
     * @param pageable 分页参数
     * @return 动态分页数据
     */
    Page<PostDTO> getUserPosts(Long userId, Pageable pageable);

    /**
     * 获取与梦想相关的动态列表
     *
     * @param dreamId 梦想ID
     * @param pageable 分页参数
     * @return 动态分页数据
     */
    Page<PostDTO> getDreamPosts(Long dreamId, Pageable pageable);

    /**
     * 创建帖子
     *
     * @param post 帖子信息
     * @return 创建后的帖子
     */
    Post createPost(Post post);

    /**
     * 根据ID获取帖子详情
     *
     * @param postId 帖子ID
     * @return 帖子视图对象
     */
    PostVO getPostVOById(Long postId);

    /**
     * 分页获取帖子列表
     *
     * @param page     页码
     * @param pageSize 每页数量
     * @param category 分类（可选）
     * @param userId   用户ID（可选）
     * @return 包含帖子列表和分页信息的Map
     */
    Map<String, Object> getPosts(int page, int pageSize, String category, Long userId);

    /**
     * 更新帖子
     *
     * @param post 帖子信息
     * @return 更新后的帖子
     */
    Post updatePost(Post post);

    /**
     * 点赞/取消点赞帖子
     *
     * @param postId 帖子ID
     * @param userId 用户ID
     * @return 是否点赞成功
     */
    boolean toggleLike(Long postId, Long userId);
} 