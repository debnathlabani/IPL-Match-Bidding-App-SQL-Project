-- 1.Show the percentage of wins of each bidder in the order of highest to lowest percentage.
select
bidder_id,bidder_name,
sum(case
when bid_status like "won" then 1
else 0 end) total_wins,
no_of_bids,
round((sum(case
when bid_status like "won" then 1
else 0 end)/no_of_bids)*100,2) win_percentage
from ipl_bidder_details ibd
join ipl_bidding_details ibid 
using(bidder_id)
join ipl_bidder_points
using(bidder_id)
group by bidder_id,bidder_name,no_of_bids
order by win_percentage desc;

-- 2.Display the number of matches conducted at each stadium with the stadium name and city.
SELECT count(im.Match_id) No_of_match,s.stadium_name,s.city
FROM ipl_match_schedule im JOIN ipl_stadium s
using (stadium_id)
group by s.STADIUM_NAME,s.city;

-- 3.In a given stadium, what is the percentage of wins by a team which has won the toss?


SELECT 
    stadium_id,stadium_name,
    SUM(CASE WHEN toss_winner = match_winner THEN 1
        ELSE 0 END) won,
    COUNT(stadium_id) total_matches,
    (SUM(CASE WHEN toss_winner = match_winner THEN 1
        ELSE 0
    END) / COUNT(stadium_id)) * 100 win_percentage
FROM
    ipl_match
        JOIN
    ipl_match_schedule USING (match_id)
        JOIN
    ipl_stadium USING (stadium_id)
WHERE
    status = 'completed'
GROUP BY stadium_id ,stadium_name
ORDER BY stadium_id ;

-- 4.Show the total bids along with the bid team and team name.


SELECT COUNT(BID_TEAM) NO_OF_BID ,IBD.BID_TEAM,IT.TEAM_NAME
FROM IPL_BIDDING_DETAILS IBD
JOIN IPL_TEAM IT
ON IBD.BID_TEAM = IT.TEAM_ID
GROUP BY IBD.BID_TEAM,IT.TEAM_NAME;

-- 5.Show the team id who won the match as per the win details.

SELECT IT.TEAM_ID, IT.TEAM_NAME, IM.TEAM_ID1, IM.TEAM_ID2,IM.MATCH_WINNER,IM.WIN_DETAILS
FROM IPL_TEAM IT
JOIN IPL_MATCH IM
ON SUBSTR(IT.REMARKS,1,3) = SUBSTR(IM.WIN_DETAILS,6,3);

-- 6.	Display total matches played, total matches won and total matches lost by the team along with its team name.

SELECT  ITS.TEAM_ID,SUM(MATCHES_PLAYED) TOTAL_MATCHES,SUM(MATCHES_WON) NO_OF_MATCH_WON,SUM(MATCHES_LOST) NO_OF_MATCH_LOST,IT.TEAM_NAME
FROM ipl_team IT
JOIN ipl_team_standings ITS
USING(TEAM_ID)
GROUP BY IT.TEAM_NAME,ITS.TEAM_ID;

-- 7.Display the bowlers for the Mumbai Indians team.
SELECT *
FROM ipl_team_players;
SELECT DISTINCT(TEAM_ID), PLAYER_ROLE
FROM ipl_team_players
WHERE PLAYER_ROLE="BOWLER" ;
SELECT IP.PLAYER_ID,IP.PLAYER_NAME,ITP.PLAYER_ROLE,IT.TEAM_NAME
FROM ipl_player IP
JOIN ipl_team_players ITP
USING(PLAYER_ID)
JOIN ipl_team IT
USING(TEAM_ID)
WHERE IT.TEAM_NAME="Mumbai Indians" AND ITP.PLAYER_ROLE="Bowler";

-- 8.How many all-rounders are there in each team, Display the teams with more than 4 all-rounders in descending order.

SELECT TEAM_NAME,ITP.PLAYER_ROLE,COUNT(ITP.PLAYER_ROLE) NO_OF_ALL_ROUNDERS
FROM ipl_team IT 
JOIN ipl_team_players ITP
USING(TEAM_ID)
WHERE ITP.PLAYER_ROLE= "All-Rounder"
GROUP BY IT.TEAM_NAME,ITP.PLAYER_ROLE
HAVING COUNT(ITP.PLAYER_ROLE) > 4;


-- 9. Write a query to get the total bidders points for each bidding status of those bidders who bid on CSK when it won the match in M. Chinnaswamy Stadium bidding year-wise.
SELECT * FROM ipl_bidder_details;
select * from ipl_bidding_details;
SELECT * FROM ipl_match_schedule;
SELECT * FROM ipl_bidder_points;
SELECT * FROM ipl_stadium;
Select * from ipl_match;
select * from ipl_team;

create view winner as
(select *, if(match_winner = 1, team_id1,team_id2) m_winner from ipl_match);

select  BIDDER_ID,bid_status, year(bid_date), sum(total_points)
from ipl_bidder_points join ipl_bidding_details using (bidder_id)
where bid_team = (select team_id from ipl_team where REMARKS = 'CSK') and
SCHEDULE_ID in (select SCHEDULE_ID from ipl_match_schedule 
					where STADIUM_ID = (select STADIUM_ID from ipl_stadium where STADIUM_NAME = "M. Chinnaswamy Stadium")
                    and MATCH_ID in (select MATCH_ID from winner where m_winner = (select team_id from ipl_team where REMARKS = 'CSK')))
group by BID_STATUS,year(BID_DATE),BIDDER_ID
order by sum(TOTAL_POINTS) desc;

-- 10.	Extract the Bowlers or All Rounders those are in the 5 highest number of wickets.

with temp as(
select TEAM_NAME, PLAYER_NAME, PLAYER_ROLE, cast(substring(performance_dtls,position('Wkt-' in performance_dtls)+4,2) as decimal) Wickets 
from ipl_team_players a join ipl_player b using (player_id)
join ipl_team using (team_id)
where PLAYER_ROLE in ('Bowler','All-Rounder')
)
select * from
(select *, dense_rank()over(order by Wickets desc) rnk from temp) t
where rnk <= 5;

-- 11.show the percentage of toss wins of each bidder and display the results in descending order based on the percentage

SELECT  BIDDER_ID,TOSS_WINNER,COUNT(TOSS_WINNER) NO_OF_TOSS_WIN,ROUND(COUNT(TOSS_WINNER)/(COUNT(bidder_id) over() )* 100,2) PERCENTAGE
FROM ipl_match IM
JOIN ipl_match_schedule
USING(MATCH_ID)
JOIN ipl_bidding_details
USING(SCHEDULE_ID)
GROUP BY BIDDER_ID,TOSS_Winner
ORDER BY percentage DESC
;

-- 12.find the IPL season which has min duration and max duration.

select *
from ipl_tournament;
with temp  as (
select TOURNMT_ID,TOURNMT_NAME,datediff(to_Date,from_date) date_diff,
 rank() over (order by  datediff(TO_DATE,from_date)) rank_min,
 rank() over (order by  datediff(TO_DATE,from_date) desc ) rank_max
 from ipl_tournament
 )

 select TOURNMT_ID,TOURNMT_NAME,date_diff Duration_days
 from temp
 where rank_min=1
 or rank_max=1;

-- 13.Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order and month-wise in ascending order
select * from ipl_bidder_details;

select ibd.Bidder_ID,ibd.Bidder_Name, year(bid_date) as Year,month(bid_date) as Month, ibp.Total_points
from ipl_bidder_details ibd join ipl_bidder_points ibp using(bidder_id) join
ipl_bidding_details ibds using(bidder_id)
where year(bid_date)= 2017
group by BIDDER_ID,year,month,TOTAL_POINTS
order by TOTAL_POINTS desc,month asc;

-- 14.	Write a query for the above question using sub queries by having the same constraints as the above question.

select bidder_id, year(bid_date) yr, month(bid_date) mt from ipl_bidding_details
where year(bid_date) = 2017
group by bidder_id, year(bid_date),month(BID_DATE);
-- bidder_id, year= 2014,extract month from bid_date
with temp as
(select bidder_id, year(bid_date) year, month(bid_date) month from ipl_bidding_details
where year(bid_date) = 2017
group by bidder_id, year(bid_date),month(BID_DATE)
)
select bidder_id, 
(select bidder_name from  ipl_bidder_details ibds where ibds.BIDDER_id = temp.BIDDER_ID) bidder_name,
year, month,
(select total_points from ipl_bidder_points a where a.BIDDER_ID = temp.BIDDER_ID) total_points
from temp
order by total_points desc, month asc;

-- 15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
select * from ipl_bidding_details;
with temp  as (
select * from
(
select BIDDER_ID,TOTAL_POINTS,
 rank() over (order by  TOTAL_POINTS) rank_min,
 rank() over (order by  TOTAL_POINTS desc ) rank_max
 from ipl_BIDDER_POINTS ) t
 where rank_max <=3 or rank_min <=3)
 
 SELECT distinct BIDDER_ID,TOTAL_POINTS,year(BID_DATE) Year,BIDDER_NAME,
 if(rank_max <=3, Bidder_name,null) Highest_Bidder,
 if(rank_min <=3 ,bidder_name, null) Lowest_bidder
 FROM TEMP JOIN ipl_bidding_details using(bidder_id)
 JOIN ipl_bidder_details using(bidder_id)
 WHERE year(bid_date)=2018 ;
 
