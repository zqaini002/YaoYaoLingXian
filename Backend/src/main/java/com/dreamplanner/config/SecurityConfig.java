package com.dreamplanner.config;

    import com.dreamplanner.service.impl.UserDetailsServiceImpl;
import com.dreamplanner.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * 安全配置
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtUtil jwtUtil;
    private final UserDetailsService userDetailsService;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }
    
    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }
    
    @Bean
    public OncePerRequestFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter(jwtUtil, userDetailsService);
    }
    
    // 创建JWT过滤器内部类
    public class JwtAuthenticationFilter extends OncePerRequestFilter {
        private final JwtUtil jwtUtil;
        private final UserDetailsService userDetailsService;
        
        public JwtAuthenticationFilter(JwtUtil jwtUtil, UserDetailsService userDetailsService) {
            this.jwtUtil = jwtUtil;
            this.userDetailsService = userDetailsService;
        }
        
        @Override
        protected void doFilterInternal(jakarta.servlet.http.HttpServletRequest request, 
                                        jakarta.servlet.http.HttpServletResponse response, 
                                        jakarta.servlet.FilterChain filterChain) 
                throws jakarta.servlet.ServletException, java.io.IOException {
            
            try {
                // 从请求头获取JWT
                String jwt = parseJwt(request);
                System.out.println("请求URI: " + request.getRequestURI());
                System.out.println("Authorization头: " + request.getHeader("Authorization"));
                System.out.println("解析的JWT: " + (jwt != null ? "有效" : "无效"));
                
                if (jwt != null) {
                    String username = jwtUtil.getUsernameFromToken(jwt);
                    System.out.println("从JWT中提取的用户名: " + username);
                    
                    // 修改判断逻辑，只要有用户名就尝试设置认证信息
                    if (username != null) {
                        // 检查SecurityContext是否已有认证
                        if (org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication() == null) {
                            System.out.println("SecurityContext中无认证信息，开始设置认证");
                        org.springframework.security.core.userdetails.UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                            System.out.println("加载的用户详情: " + userDetails.getUsername());
                        
                        if (jwtUtil.validateToken(jwt, userDetails.getUsername())) {
                            org.springframework.security.authentication.UsernamePasswordAuthenticationToken authentication = 
                                new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                                    userDetails, null, userDetails.getAuthorities());
                            
                            authentication.setDetails(new org.springframework.security.web.authentication.WebAuthenticationDetailsSource().buildDetails(request));
                            
                            org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(authentication);
                                System.out.println("用户认证成功，SecurityContext已更新");
                            } else {
                                System.out.println("JWT验证失败");
                            }
                        } else {
                            System.out.println("SecurityContext中已有认证信息");
                        }
                    } else {
                        System.out.println("从JWT中提取的用户名为空");
                        }
                } else {
                    System.out.println("请求中无JWT令牌");
                }
            } catch (Exception e) {
                System.err.println("认证过程出现错误: " + e.getMessage());
                e.printStackTrace();
            }
            
            filterChain.doFilter(request, response);
        }
        
        /**
         * 从请求头中解析JWT令牌
         */
        private String parseJwt(jakarta.servlet.http.HttpServletRequest request) {
            String headerAuth = request.getHeader("Authorization");
            
            if (headerAuth != null && !headerAuth.isEmpty() && headerAuth.startsWith("Bearer ")) {
                return headerAuth.substring(7);
            }
            
            return null;
        }
    }
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                .requestMatchers("/api/auth/**", "/auth/**").permitAll()
                .requestMatchers("/api/files/**", "/files/**").permitAll()
                .requestMatchers("/api/posts/public/**", "/posts/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);
            
        return http.build();
    }
} 