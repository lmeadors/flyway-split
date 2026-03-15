-- =============================================================================
-- Bookstore repeatable migration: book_listing view
--
-- Owned by: Bookstore squad
-- Run as:   app_user
--
-- Repeatable migrations (R__ prefix) re-run whenever this file changes.
-- Edit this file in place to update the view — no new versioned migration needed.
-- =============================================================================

CREATE OR REPLACE VIEW bookstore.book_listing AS
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
