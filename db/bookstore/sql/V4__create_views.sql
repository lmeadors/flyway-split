-- =============================================================================
-- Bookstore migration: Create reporting views
--
-- Owned by: Bookstore squad
-- Run as:   app_user
-- =============================================================================

-- A convenient view that joins books with their authors into a single row.
CREATE VIEW bookstore.book_listing AS
    SELECT
        b.id,
        b.title,
        b.isbn,
        b.published_date,
        b.price,
        string_agg(
            a.last_name || ', ' || a.first_name,
            '; '
            ORDER BY a.last_name, a.first_name
        ) AS authors
    FROM bookstore.books b
    LEFT JOIN bookstore.book_authors ba ON b.id = ba.book_id
    LEFT JOIN bookstore.authors      a  ON ba.author_id = a.id
    GROUP BY b.id, b.title, b.isbn, b.published_date, b.price;
