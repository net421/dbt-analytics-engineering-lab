{% macro safe_ratio(numerator, denominator) %}
    ({{ numerator }}) / nullif(cast(({{ denominator }}) as double), 0)
{% endmacro %}
