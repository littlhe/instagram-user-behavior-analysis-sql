-- Instagram User Behavior Analysis
-- Author: Prajyot Naik
-- Description: SQL queries for analyzing engagement and user activity


USE ig_clone ;

-- OBJECTIVE QUESTIONS :-
-- Q1) Are there any tables with duplicate or missing NULL values?

-- 		PART A:  Check for Duplicate Records:

--     Duplicate Usernames (users table):
			SELECT username, COUNT(*) AS duplicate_count
			FROM users
			GROUP BY username
			HAVING COUNT(*) > 1 ;

--     Duplicate Tag Names (tags table):
			SELECT tag_name, COUNT(*) AS duplicate_count
			FROM tags
			GROUP BY tag_name
			HAVING COUNT(*) > 1 ;
            
--     Duplicate Likes (same user liking same photo multiple times):
			SELECT user_id, photo_id, COUNT(*) AS duplicate_count
			FROM likes
			GROUP BY user_id, photo_id
			HAVING COUNT(*) > 1 ;
            
--     Duplicate Follows (same follow relationship repeated):
			SELECT follower_id, followee_id, COUNT(*) AS duplicate_count
			FROM follows
			GROUP BY follower_id, followee_id
			HAVING COUNT(*) > 1 ;

--     Duplicate Photo Tags:
			SELECT photo_id, tag_id, COUNT(*) AS duplicate_count
			FROM photo_tags
			GROUP BY photo_id, tag_id
			HAVING COUNT(*) > 1 ;
            
-- 		PART B:  Check for Duplicate Records:

--     NULL values in users:
			SELECT *
			FROM users
			WHERE username IS NULL OR created_at IS NULL ;
            
--     NULL values in photos:
			SELECT *
			FROM photos
			WHERE image_url IS NULL OR user_id IS NULL ;
            
--     NULL values in comments:
			SELECT *
			FROM comments
			WHERE comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL ;
            
--     NULL values in tags:
			SELECT *
			FROM tags
			WHERE tag_name IS NULL ;
            
--     Count NULLs:
			SELECT
				SUM(username IS NULL) AS null_usernames,
				SUM(created_at IS NULL) AS null_created_dates
			FROM users ;
       
       
-- Q2) What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

				SELECT 
						activity_level,
						COUNT(*) AS number_of_users
					FROM (
						SELECT 
							CASE 
								WHEN activity = 0 THEN 'Inactive'
								WHEN activity BETWEEN 1 AND 5 THEN 'Low Activity'
								WHEN activity BETWEEN 6 AND 20 THEN 'Medium Activity'
								ELSE 'High Activity'
							END AS activity_level
						FROM (
							SELECT 
								u.id,
								COUNT(DISTINCT p.id) +
								COUNT(DISTINCT l.photo_id) +
								COUNT(DISTINCT c.id) AS activity
							FROM users u
							LEFT JOIN photos p ON u.id = p.user_id
							LEFT JOIN likes l ON u.id = l.user_id
							LEFT JOIN comments c ON u.id = c.user_id
							GROUP BY u.id
						) AS activity_data
					) AS categorized
					GROUP BY activity_level
					ORDER BY activity_level ASC ;
       
       
-- Q3) Calculate the average number of tags per post (photo_tags and photos tables)?
			SELECT 
				AVG(tag_count) AS avg_tags_per_post
			FROM (
				SELECT 
					p.id,
					COUNT(pt.tag_id) AS tag_count
				FROM photos AS p
				LEFT JOIN photo_tags AS pt 
					ON p.id = pt.photo_id
				GROUP BY p.id
			) AS t ;
       
       
-- Q4) Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.
			SELECT 
				u.id,
				u.username,
				COUNT(DISTINCT l.user_id, l.photo_id) AS total_likes_received,
				COUNT(DISTINCT c.id) AS total_comments_received,
				(
					COUNT(DISTINCT l.user_id, l.photo_id) +
					COUNT(DISTINCT c.id)
				) AS total_engagement,
				RANK() OVER (
					ORDER BY 
					COUNT(DISTINCT l.user_id, l.photo_id) +
					COUNT(DISTINCT c.id) DESC
				) AS engagement_rank
			FROM users AS u
			JOIN photos AS p 
				ON u.id = p.user_id
			LEFT JOIN likes AS l 
				ON p.id = l.photo_id
			LEFT JOIN comments AS c 
				ON p.id = c.photo_id
			GROUP BY u.id, u.username
			ORDER BY engagement_rank ASC ;


-- Q5) Which users have the highest number of followers and followings?
			SELECT 
				u.id,
				u.username,
				COUNT(DISTINCT f1.follower_id) AS followers_count,
				COUNT(DISTINCT f2.followee_id) AS following_count
			FROM users AS u
			LEFT JOIN follows f1 
				ON u.id = f1.followee_id     -- followers
			LEFT JOIN follows f2 
				ON u.id = f2.follower_id     -- followings
			GROUP BY u.id, u.username
			ORDER BY followers_count DESC, following_count DESC ;
            

-- Q6) Calculate the average engagement rate (likes, comments) per post for each user.
			SELECT 
				u.id,
				u.username,
				AVG(
					IFNULL(l.like_count, 0) + 
					IFNULL(c.comment_count, 0)
				) AS avg_engagement_per_post
			FROM users AS u
			JOIN photos AS p 
				ON u.id = p.user_id

			LEFT JOIN (
				SELECT photo_id, COUNT(*) AS like_count
				FROM likes
				GROUP BY photo_id
			) AS l ON p.id = l.photo_id

			LEFT JOIN (
				SELECT photo_id, COUNT(*) AS comment_count
				FROM comments
				GROUP BY photo_id
			) AS c ON p.id = c.photo_id

			GROUP BY u.id, u.username
			ORDER BY avg_engagement_per_post DESC ;


-- Q7) Get the list of users who have never liked any post (users and likes tables)
			SELECT 
				u.id,
				u.username
			FROM users AS u
			LEFT JOIN likes AS l 
				ON u.id = l.user_id
			WHERE l.user_id IS NULL ;
            

-- Q8) Get the list of users who have never liked any post (users and likes tables)

-- 		PART A:  Most Popular Hashtags (Trending Topics):
			SELECT 
				t.tag_name,
				COUNT(pt.photo_id) AS usage_count
			FROM tags AS t
			JOIN photo_tags AS pt 
				ON t.id = pt.tag_id
			GROUP BY t.id, t.tag_name
			ORDER BY usage_count DESC ;
            
-- 		PART B:  Top Users Posting Content (Content Creators):
			SELECT 
				u.id,
				u.username,
				COUNT(p.id) AS total_posts
			FROM users AS u
			JOIN photos AS p 
				ON u.id = p.user_id
			GROUP BY u.id, u.username
			ORDER BY total_posts DESC ;

-- 		PART C:  Users Interested in Specific Topics (via Hashtags):
			SELECT 
				u.id,
				u.username,
				t.tag_name,
				COUNT(*) AS tag_usage
			FROM users AS u
			JOIN photos AS p 
				ON u.id = p.user_id
			JOIN photo_tags AS pt 
				ON p.id = pt.photo_id
			JOIN tags AS t 
				ON pt.tag_id = t.id
			GROUP BY u.id, u.username, t.tag_name
			ORDER BY tag_usage DESC ;
            
-- 		PART D:  Most Engaging Content by Hashtag:
			SELECT 
				t.tag_name,
				COUNT(DISTINCT l.user_id) AS total_likes,
				COUNT(DISTINCT c.id) AS total_comments,
				(
					COUNT(DISTINCT l.user_id) +
					COUNT(DISTINCT c.id)
				) AS total_engagement
			FROM tags AS t
			JOIN photo_tags AS pt ON t.id = pt.tag_id
			JOIN photos AS p ON pt.photo_id = p.id
			LEFT JOIN likes AS l ON p.id = l.photo_id
			LEFT JOIN comments AS c ON p.id = c.photo_id
			GROUP BY t.id, t.tag_name
			ORDER BY total_engagement DESC ;
            
-- 		PART E:  Identify Influencers in Specific Niches:
			SELECT 
				u.id,
				u.username,
				COUNT(DISTINCT l.user_id) +
				COUNT(DISTINCT c.id) AS engagement
			FROM users AS u
			JOIN photos AS p ON u.id = p.user_id
			JOIN photo_tags AS pt ON p.id = pt.photo_id
			LEFT JOIN likes AS l ON p.id = l.photo_id
			LEFT JOIN comments AS c ON p.id = c.photo_id
			GROUP BY u.id, u.username
			ORDER BY engagement DESC ;
            

-- Q9) Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?

-- 		PART A:  User Activity Level:
			SELECT 
				u.id,
				u.username,
				COUNT(DISTINCT p.id) AS posts,
				COUNT(DISTINCT l.photo_id) AS likes_given,
				COUNT(DISTINCT c.id) AS comments_made,
				(
					COUNT(DISTINCT p.id) +
					COUNT(DISTINCT l.photo_id) +
					COUNT(DISTINCT c.id)
				) AS total_activity
			FROM users AS u
			LEFT JOIN photos AS p ON u.id = p.user_id
			LEFT JOIN likes AS l ON u.id = l.user_id
			LEFT JOIN comments AS c ON u.id = c.user_id
			GROUP BY u.id, u.username
			ORDER BY total_activity DESC ;
            
-- 		PART B:  Engagement Received on Their Content:
			SELECT 
				u.id,
				u.username,
				COUNT(DISTINCT l.user_id) AS likes_received,
				COUNT(DISTINCT c.id) AS comments_received,
				(
					COUNT(DISTINCT l.user_id) +
					COUNT(DISTINCT c.id)
				) AS engagement_received
			FROM users AS u
			JOIN photos AS p ON u.id = p.user_id
			LEFT JOIN likes AS l ON p.id = l.photo_id
			LEFT JOIN comments AS c ON p.id = c.photo_id
			GROUP BY u.id, u.username
			ORDER BY engagement_received DESC ;
            
-- 		PART C:  Engagement by Hashtag:
			SELECT 
				t.tag_name,
				COUNT(DISTINCT l.user_id) +
				COUNT(DISTINCT c.id) AS total_engagement
			FROM tags AS t
			JOIN photo_tags AS pt ON t.id = pt.tag_id
			JOIN photos AS p ON pt.photo_id = p.id
			LEFT JOIN likes AS l ON p.id = l.photo_id
			LEFT JOIN comments AS c ON p.id = c.photo_id
			GROUP BY t.id, t.tag_name
			ORDER BY total_engagement DESC ;


-- Q10) Calculate the total number of likes, comments, and photo tags for each user.
			SELECT 
				u.id,
				u.username,
				IFNULL(l.total_likes, 0) AS total_likes_received,
				IFNULL(c.total_comments, 0) AS total_comments_received,
				IFNULL(pt.total_tags, 0) AS total_photo_tags
			FROM users AS u

			LEFT JOIN photos AS p 
				ON u.id = p.user_id

			LEFT JOIN (
				SELECT 
					p.user_id,
					COUNT(*) AS total_likes
				FROM photos AS p
				JOIN likes AS l 
					ON p.id = l.photo_id
				GROUP BY p.user_id
			) l ON u.id = l.user_id

			LEFT JOIN (
				SELECT 
					p.user_id,
					COUNT(*) AS total_comments
				FROM photos AS p
				JOIN comments AS c 
					ON p.id = c.photo_id
				GROUP BY p.user_id
			) c ON u.id = c.user_id

			LEFT JOIN (
				SELECT 
					p.user_id,
					COUNT(*) AS total_tags
				FROM photos AS p
				JOIN photo_tags pt 
					ON p.id = pt.photo_id
				GROUP BY p.user_id
			) pt ON u.id = pt.user_id

			GROUP BY u.id, u.username
			ORDER BY u.id ASC ;
            

-- Q11)	Rank users based on their total engagement (likes, comments, shares) over a month.
			SELECT 
				u.id,
				u.username,
				COUNT(DISTINCT l.user_id, l.photo_id) AS likes_received,
				COUNT(DISTINCT c.id) AS comments_received,
				(
					COUNT(DISTINCT l.user_id, l.photo_id) +
					COUNT(DISTINCT c.id)
				) AS total_engagement,
				RANK() OVER (
					ORDER BY 
					COUNT(DISTINCT l.user_id, l.photo_id) +
					COUNT(DISTINCT c.id) DESC
				) AS engagement_rank
			FROM users AS u
			JOIN photos AS p 
				ON u.id = p.user_id

			LEFT JOIN likes AS l 
				ON p.id = l.photo_id
				AND l.created_at >= '2024-01-01'
				AND l.created_at < '2024-02-01'

			LEFT JOIN comments AS c 
				ON p.id = c.photo_id
				AND c.created_at >= '2024-01-01'
				AND c.created_at < '2024-02-01'

			GROUP BY u.id, u.username
			ORDER BY engagement_rank ASC ;
            

-- Q12)	Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.
			WITH hashtag_avg_likes AS (
				SELECT 
					t.id,
					t.tag_name,
					AVG(IFNULL(l.like_count, 0)) AS avg_likes
				FROM tags AS t
				JOIN photo_tags AS pt 
					ON t.id = pt.tag_id
				JOIN photos AS p 
					ON pt.photo_id = p.id

				LEFT JOIN (
					SELECT 
						photo_id,
						COUNT(*) AS like_count
					FROM likes
					GROUP BY photo_id
				) l ON p.id = l.photo_id

				GROUP BY t.id, t.tag_name
			)

			SELECT *
			FROM hashtag_avg_likes
			ORDER BY avg_likes DESC ;


-- Q13)	Retrieve the users who have started following someone after being followed by that person
			SELECT 
				f1.follower_id AS user_A,
				f1.followee_id AS user_B,
				f1.created_at AS A_followed_B_at,
				f2.created_at AS B_followed_A_at
			FROM follows f1
			JOIN follows f2
				ON f1.follower_id = f2.followee_id
				AND f1.followee_id = f2.follower_id
				AND f2.created_at > f1.created_at ;
			
            
            
-- SUBJECTIVE QUESTIONS :-
-- Q1) Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
			WITH cte1 AS (
							SELECT 
									u.id AS UserID,
											COUNT(DISTINCT l.photo_id) AS NumberOfLikes,
											COUNT(DISTINCT c.id) AS NumberOfComments,
											COUNT(DISTINCT p.id) AS NumberOfPosts
										FROM users AS u
										LEFT JOIN likes AS l
											ON u.id = l.user_id
										LEFT JOIN comments AS c
											ON u.id = c.user_id
										LEFT JOIN photos AS p
											ON u.id = p.user_id
										GROUP BY u.id
									)

									SELECT 
										UserID,
										NumberOfLikes,
										NumberOfPosts,
										NumberOfComments,
										ROUND(
											(NumberOfLikes + NumberOfComments) / 
											NULLIF(NumberOfPosts, 0), 
											2
										) AS engagement_rate

									FROM cte1

									ORDER BY 
										engagement_rate DESC,
										NumberOfPosts DESC,
										NumberOfLikes DESC,
										NumberOfComments DESC ;
                            

-- Q2) For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again? 
				SELECT 
					u.id,
					u.username
				FROM users AS u
				LEFT JOIN photos AS p 
					ON u.id = p.user_id
				LEFT JOIN likes AS l 
					ON u.id = l.user_id
				LEFT JOIN comments AS c 
					ON u.id = c.user_id
				WHERE 
					p.id IS NULL
					AND l.user_id IS NULL
					AND c.user_id IS NULL ;
                    

-- Q3) For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?
			WITH tag_engagement AS (
				SELECT 
					t.id AS tag_id,
					t.tag_name,
					COUNT(DISTINCT p.id) AS total_posts,
					COUNT(DISTINCT l.user_id, l.photo_id) AS total_likes,
					COUNT(DISTINCT c.id) AS total_comments
				FROM tags AS t
				JOIN photo_tags AS pt 
					ON t.id = pt.tag_id
				JOIN photos AS p 
					ON pt.photo_id = p.id
				LEFT JOIN likes AS l 
					ON p.id = l.photo_id
				LEFT JOIN comments AS c 
					ON p.id = c.photo_id
				GROUP BY t.id, t.tag_name
			)

			SELECT 
				tag_id,
				tag_name,
				ROUND(
					(total_likes + total_comments) / 
					NULLIF(total_posts, 0), 
					2
				) AS engagement_rate
			FROM tag_engagement
			ORDER BY engagement_rate DESC ;
            

-- Q4) For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?
						WITH likes_count AS (
				SELECT photo_id, COUNT(*) AS total_likes
				FROM likes
				GROUP BY photo_id
			),
			comments_count AS (
				SELECT photo_id, COUNT(*) AS total_comments
				FROM comments
				GROUP BY photo_id
			)

			SELECT 
				HOUR(p.created_dat) AS hour_of_day,
				DAYNAME(p.created_dat) AS day_of_week,

				COUNT(p.id) AS total_posts,
				SUM(IFNULL(l.total_likes, 0)) AS total_likes,
				SUM(IFNULL(c.total_comments, 0)) AS total_comments,

				ROUND(
					(SUM(IFNULL(l.total_likes, 0)) +
					 SUM(IFNULL(c.total_comments, 0))) / 
					COUNT(p.id), 
					2
				) AS avg_engagement

			FROM photos AS p
			LEFT JOIN likes_count AS l 
				ON p.id = l.photo_id
			LEFT JOIN comments_count AS c 
				ON p.id = c.photo_id

			GROUP BY hour_of_day, day_of_week
			ORDER BY avg_engagement DESC ;
            

-- Q5) Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
			WITH engagement AS (
				SELECT 
					u.id AS user_id,
					COUNT(DISTINCT p.id) AS total_posts,
					COUNT(DISTINCT l.user_id, l.photo_id) AS total_likes_received,
					COUNT(DISTINCT c.id) AS total_comments_received
				FROM users AS u
				JOIN photos AS p 
					ON u.id = p.user_id
				LEFT JOIN likes AS l 
					ON p.id = l.photo_id
				LEFT JOIN comments AS c 
					ON p.id = c.photo_id
				GROUP BY u.id
			),

			followers AS (
				SELECT 
					followee_id AS user_id,
					COUNT(DISTINCT follower_id) AS followers_count
				FROM follows
				GROUP BY followee_id
			)

			SELECT 
				e.user_id,
				f.followers_count,
				ROUND(
					(e.total_likes_received + e.total_comments_received) /
					NULLIF(e.total_posts, 0),
					2
				) AS engagement_rate
			FROM engagement AS e
			JOIN followers AS f 
				ON e.user_id = f.user_id
			ORDER BY engagement_rate DESC, followers_count DESC ;
            

-- Q6) Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?
			WITH user_activity AS (
				SELECT 
					u.id AS user_id,
					u.username,

					COUNT(DISTINCT p.id) AS total_posts,
					COUNT(DISTINCT l.photo_id) AS total_likes_given,
					COUNT(DISTINCT c.id) AS total_comments_made,

					(
						COUNT(DISTINCT p.id) +
						COUNT(DISTINCT l.photo_id) +
						COUNT(DISTINCT c.id)
					) AS overall_engagement

				FROM users AS u
				LEFT JOIN photos AS p 
					ON u.id = p.user_id
				LEFT JOIN likes AS l 
					ON u.id = l.user_id
				LEFT JOIN comments AS c 
					ON u.id = c.user_id

				GROUP BY u.id, u.username
			)

			SELECT 
				user_id,
				username,
				total_posts,
				total_likes_given,
				total_comments_made,
				overall_engagement,

				CASE
					WHEN overall_engagement >= 50 THEN 'Highly Engaged'
					WHEN overall_engagement BETWEEN 10 AND 49 THEN 'Moderately Engaged'
					ELSE 'Inactive'
				END AS engagement_segment

			FROM user_activity
			ORDER BY overall_engagement DESC ;
            

-- Q7) If data on ad campaigns (impressions, clicks, conversions) is available, how would you measure their effectiveness and optimize future campaigns?
			SELECT 
				campaign_name,

				impressions,
				clicks,
				conversions,
				cost,
				revenue,

				-- Click Through Rate
				ROUND((clicks / NULLIF(impressions, 0)) * 100, 2) AS CTR,

				-- Conversion Rate
				ROUND((conversions / NULLIF(clicks, 0)) * 100, 2) AS conversion_rate,

				-- Cost Per Click
				ROUND(cost / NULLIF(clicks, 0), 2) AS CPC,

				-- Return on Investment
				ROUND(((revenue - cost) / NULLIF(cost, 0)) * 100, 2) AS ROI

			FROM ad_campaigns
			ORDER BY ROI DESC ;
            

-- Q8) How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?
			WITH user_metrics AS (
				SELECT 
					u.id AS user_id,
					u.username,

					COUNT(DISTINCT p.id) AS total_posts,
					COUNT(DISTINCT l2.user_id, l2.photo_id) AS likes_received,
					COUNT(DISTINCT c2.id) AS comments_received,
					COUNT(DISTINCT f.follower_id) AS followers_count

				FROM users AS u

				LEFT JOIN photos AS p 
					ON u.id = p.user_id

				LEFT JOIN likes AS l2 
					ON p.id = l2.photo_id

				LEFT JOIN comments AS c2 
					ON p.id = c2.photo_id

				LEFT JOIN follows AS f 
					ON u.id = f.followee_id

				GROUP BY u.id, u.username
			)

			SELECT 
				user_id,
				username,
				total_posts,
				followers_count,

				ROUND(
					(likes_received + comments_received) /
					NULLIF(total_posts, 0),
					2
				) AS engagement_per_post

			FROM user_metrics

			WHERE 
				followers_count >= 50      -- influence threshold
				AND total_posts >= 5       -- activity threshold

			ORDER BY 
				followers_count DESC,
				engagement_per_post DESC ;
    
    
-- Q9) How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?
-- Theory ANS (Word Doc)


-- Q10) Assuming there's a "User_Interactions" table tracking user engagements, how can you update the "Engagement_Type" column to change all instances of "Like" to "Heart" to align with Instagram's terminology?
			UPDATE User_Interactions
			SET Engagement_Type = 'Heart'
			WHERE Engagement_Type = 'Like';
