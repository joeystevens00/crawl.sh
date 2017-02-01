select link, locationDiscovered, count(*) from crawler.links
group by link, locationDiscovered
having count(*) > 1
