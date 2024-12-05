--
-- PostgreSQL database dump
--

-- Dumped from database version 10.23 (Ubuntu 10.23-1.pgdg18.04+1)
-- Dumped by pg_dump version 15.3 (Ubuntu 15.3-1.pgdg18.04+1)

-- Started on 2024-08-21 13:26:14 +06

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 9 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 3 (class 3079 OID 92487)
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- TOC entry 7626 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- TOC entry 2 (class 3079 OID 92863)
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- TOC entry 7627 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- TOC entry 1209 (class 1247 OID 92885)
-- Name: enum_access_tokens_access_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_access_tokens_access_level AS ENUM (
    'read',
    'write'
);


ALTER TYPE public.enum_access_tokens_access_level OWNER TO postgres;

--
-- TOC entry 824 (class 1255 OID 92889)
-- Name: prevent_delete_truncate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_delete_truncate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP = 'DELETE' OR TG_OP = 'TRUNCATE' THEN
    RAISE EXCEPTION 'DELETE and TRUNCATE commands are not allowed on %', TG_RELNAME;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.prevent_delete_truncate() OWNER TO postgres;

SET default_tablespace = '';

--
-- TOC entry 201 (class 1259 OID 92890)
-- Name: access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.access_tokens (
    id integer NOT NULL,
    token character varying(255) NOT NULL,
    access_level public.enum_access_tokens_access_level DEFAULT 'read'::public.enum_access_tokens_access_level,
    rate_limit integer,
    whitelisted_ids jsonb,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.access_tokens OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 92897)
-- Name: access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.access_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.access_tokens_id_seq OWNER TO postgres;

--
-- TOC entry 7628 (class 0 OID 0)
-- Dependencies: 202
-- Name: access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.access_tokens_id_seq OWNED BY public.access_tokens.id;


--
-- TOC entry 203 (class 1259 OID 92899)
-- Name: account_balances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_balances (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    current_balance numeric(12,2) DEFAULT 0.0,
    promo_balance numeric(12,2) DEFAULT 0.0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint,
    carry_over numeric,
    is_last_debit_non_promo_receipt boolean DEFAULT false
);


ALTER TABLE public.account_balances OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 92908)
-- Name: account_balances_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.account_balances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.account_balances_id_seq OWNER TO postgres;

--
-- TOC entry 7629 (class 0 OID 0)
-- Dependencies: 204
-- Name: account_balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.account_balances_id_seq OWNED BY public.account_balances.id;


--
-- TOC entry 205 (class 1259 OID 92910)
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    company_name character varying,
    timezone character varying,
    adgroup_filter_enabled boolean DEFAULT false,
    discarded_at timestamp(6) without time zone,
    status character varying DEFAULT 'onboarding'::character varying,
    activation_time timestamp(6) without time zone,
    account_manager_id bigint,
    sales_manager_id bigint,
    internal boolean DEFAULT false NOT NULL,
    insurance_carrier_id bigint,
    enterprise boolean DEFAULT false,
    budget_option_monthly_unlimited boolean DEFAULT false,
    budget_option_monthly_budget boolean DEFAULT false,
    budget_option_monthly_volume boolean DEFAULT false,
    budget_option_daily_unlimited boolean DEFAULT true,
    budget_option_daily_budget boolean DEFAULT false,
    budget_option_daily_volume boolean DEFAULT true,
    budget_option_volume_by_day boolean DEFAULT false,
    budget_option_budget_by_day boolean DEFAULT false,
    license_number character varying,
    call_details_enabled boolean DEFAULT true,
    partner boolean DEFAULT false,
    terms_of_service_id bigint,
    consecutive_post_rejects integer DEFAULT 10 NOT NULL,
    individiual_zipcodes_enabled boolean DEFAULT false NOT NULL,
    create_password_mail_sent_at timestamp(6) without time zone,
    pace numeric(20,2) DEFAULT 0.0,
    call_summary_enabled boolean DEFAULT false,
    source_settings_enabled boolean DEFAULT false NOT NULL,
    bid_level_report boolean DEFAULT false,
    uuid character varying,
    close_io_lead_id character varying,
    folio_eligible boolean DEFAULT false NOT NULL,
    cost_share_eligible boolean DEFAULT false NOT NULL,
    close_com_custom_obj_id character varying
);


ALTER TABLE public.accounts OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 92938)
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_id_seq OWNER TO postgres;

--
-- TOC entry 7630 (class 0 OID 0)
-- Dependencies: 206
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- TOC entry 207 (class 1259 OID 92940)
-- Name: ad_contents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_contents (
    id bigint NOT NULL,
    ad_id bigint NOT NULL,
    title character varying,
    bullet_points text,
    display_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    display_name character varying
);


ALTER TABLE public.ad_contents OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 92946)
-- Name: ad_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_contents_id_seq OWNER TO postgres;

--
-- TOC entry 7631 (class 0 OID 0)
-- Dependencies: 208
-- Name: ad_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_contents_id_seq OWNED BY public.ad_contents.id;


--
-- TOC entry 209 (class 1259 OID 92948)
-- Name: ad_group_ads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_group_ads (
    id bigint NOT NULL,
    ad_id bigint NOT NULL,
    ad_group_id bigint NOT NULL,
    platform character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    weight integer DEFAULT 100,
    weight_type character varying,
    active_weight integer DEFAULT 0
);


ALTER TABLE public.ad_group_ads OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 92956)
-- Name: ad_group_ads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_group_ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_group_ads_id_seq OWNER TO postgres;

--
-- TOC entry 7632 (class 0 OID 0)
-- Dependencies: 210
-- Name: ad_group_ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_group_ads_id_seq OWNED BY public.ad_group_ads.id;


--
-- TOC entry 211 (class 1259 OID 92958)
-- Name: ad_group_filter_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_group_filter_groups (
    id bigint NOT NULL,
    ad_group_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.ad_group_filter_groups OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 92961)
-- Name: ad_group_filter_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_group_filter_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_group_filter_groups_id_seq OWNER TO postgres;

--
-- TOC entry 7633 (class 0 OID 0)
-- Dependencies: 212
-- Name: ad_group_filter_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_group_filter_groups_id_seq OWNED BY public.ad_group_filter_groups.id;


--
-- TOC entry 213 (class 1259 OID 92963)
-- Name: ad_group_filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_group_filters (
    id bigint NOT NULL,
    filter_value character varying,
    include boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    ad_group_filter_group_id bigint NOT NULL,
    ad_group_id bigint NOT NULL,
    sf_filter_id bigint NOT NULL,
    filter_value_min character varying,
    filter_value_max character varying,
    price numeric(20,2),
    discarded_at timestamp(6) without time zone,
    filter_value_array text[] DEFAULT '{}'::text[],
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.ad_group_filters OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 92971)
-- Name: ad_group_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_group_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_group_filters_id_seq OWNER TO postgres;

--
-- TOC entry 7634 (class 0 OID 0)
-- Dependencies: 214
-- Name: ad_group_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_group_filters_id_seq OWNED BY public.ad_group_filters.id;


--
-- TOC entry 215 (class 1259 OID 92973)
-- Name: ad_group_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_group_locations (
    id bigint NOT NULL,
    zip character varying,
    state character varying,
    ad_group_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.ad_group_locations OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 92979)
-- Name: ad_group_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_group_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_group_locations_id_seq OWNER TO postgres;

--
-- TOC entry 7635 (class 0 OID 0)
-- Dependencies: 216
-- Name: ad_group_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_group_locations_id_seq OWNED BY public.ad_group_locations.id;


--
-- TOC entry 217 (class 1259 OID 92981)
-- Name: ad_group_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_group_notes (
    id bigint NOT NULL,
    text text,
    admin_user_id bigint NOT NULL,
    ad_group_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ad_group_notes OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 92987)
-- Name: ad_group_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_group_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_group_notes_id_seq OWNER TO postgres;

--
-- TOC entry 7636 (class 0 OID 0)
-- Dependencies: 218
-- Name: ad_group_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_group_notes_id_seq OWNED BY public.ad_group_notes.id;


--
-- TOC entry 219 (class 1259 OID 92989)
-- Name: ad_group_pixel_columns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_group_pixel_columns (
    id bigint NOT NULL,
    click_conversion_pixel_id bigint NOT NULL,
    disp_count boolean,
    disp_cvr boolean,
    disp_cpa boolean,
    disp_rev boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    disp_leads_count boolean DEFAULT true,
    disp_leads_cvr boolean DEFAULT true,
    disp_leads_cpa boolean DEFAULT true,
    disp_leads_rev boolean DEFAULT true,
    disp_calls_count boolean DEFAULT true,
    disp_calls_cvr boolean DEFAULT true,
    disp_calls_cpa boolean DEFAULT true,
    disp_calls_rev boolean DEFAULT true
);


ALTER TABLE public.ad_group_pixel_columns OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 93000)
-- Name: ad_group_pixel_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_group_pixel_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_group_pixel_columns_id_seq OWNER TO postgres;

--
-- TOC entry 7637 (class 0 OID 0)
-- Dependencies: 220
-- Name: ad_group_pixel_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_group_pixel_columns_id_seq OWNED BY public.ad_group_pixel_columns.id;


--
-- TOC entry 221 (class 1259 OID 93002)
-- Name: ad_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_groups (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint NOT NULL,
    base_bid_price numeric(20,2),
    ad_group_name character varying,
    active boolean,
    default_state character varying,
    discarded_at timestamp(6) without time zone,
    rtb_cm numeric(5,2)
);


ALTER TABLE public.ad_groups OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 93008)
-- Name: ad_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ad_groups_id_seq OWNER TO postgres;

--
-- TOC entry 7638 (class 0 OID 0)
-- Dependencies: 222
-- Name: ad_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_groups_id_seq OWNED BY public.ad_groups.id;


--
-- TOC entry 223 (class 1259 OID 93010)
-- Name: admin_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_assignments (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    admin_role_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_assignments OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 93013)
-- Name: admin_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_assignments_id_seq OWNER TO postgres;

--
-- TOC entry 7639 (class 0 OID 0)
-- Dependencies: 224
-- Name: admin_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_assignments_id_seq OWNED BY public.admin_assignments.id;


--
-- TOC entry 225 (class 1259 OID 93015)
-- Name: admin_clients_customize_columns_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_clients_customize_columns_orders (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    account_id integer DEFAULT 0,
    account_name integer DEFAULT 0,
    carrier_id integer DEFAULT 0,
    status integer DEFAULT 0,
    location integer DEFAULT 0,
    sales_rep integer DEFAULT 0,
    account_manager integer DEFAULT 0,
    date integer DEFAULT 0,
    email integer DEFAULT 0,
    phone integer DEFAULT 0,
    activation_time integer DEFAULT 0,
    internal integer DEFAULT 0,
    company_name integer DEFAULT 0,
    timezone integer DEFAULT 0,
    address integer DEFAULT 0,
    city integer DEFAULT 0,
    state integer DEFAULT 0,
    zip integer DEFAULT 0,
    is_mfa_enabled integer DEFAULT 0,
    invoice integer DEFAULT 0,
    rebill integer DEFAULT 0,
    rebill_amount integer DEFAULT 0,
    credit_limit integer DEFAULT 0,
    rebill_failure integer DEFAULT 0,
    cash_balance integer DEFAULT 0,
    promo_balance integer DEFAULT 0,
    total_balance integer DEFAULT 0,
    total_spend integer DEFAULT 0,
    total_campaigns integer DEFAULT 0,
    products integer DEFAULT 0,
    enterprise integer DEFAULT 0,
    call_transcription integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_clients_customize_columns_orders OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 93050)
-- Name: admin_clients_customize_columns_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_clients_customize_columns_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_clients_customize_columns_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7640 (class 0 OID 0)
-- Dependencies: 226
-- Name: admin_clients_customize_columns_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_clients_customize_columns_orders_id_seq OWNED BY public.admin_clients_customize_columns_orders.id;


--
-- TOC entry 227 (class 1259 OID 93052)
-- Name: admin_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_features (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_features OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 93058)
-- Name: admin_features_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_features_id_seq OWNER TO postgres;

--
-- TOC entry 7641 (class 0 OID 0)
-- Dependencies: 228
-- Name: admin_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_features_id_seq OWNED BY public.admin_features.id;


--
-- TOC entry 229 (class 1259 OID 93060)
-- Name: admin_notification_template_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_notification_template_types (
    id bigint NOT NULL,
    admin_notification_template_id bigint NOT NULL,
    admin_notification_type_id bigint NOT NULL,
    active boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.admin_notification_template_types OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 93063)
-- Name: admin_notification_template_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_notification_template_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_notification_template_types_id_seq OWNER TO postgres;

--
-- TOC entry 7642 (class 0 OID 0)
-- Dependencies: 230
-- Name: admin_notification_template_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_notification_template_types_id_seq OWNED BY public.admin_notification_template_types.id;


--
-- TOC entry 231 (class 1259 OID 93065)
-- Name: admin_notification_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_notification_templates (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.admin_notification_templates OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 93071)
-- Name: admin_notification_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_notification_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_notification_templates_id_seq OWNER TO postgres;

--
-- TOC entry 7643 (class 0 OID 0)
-- Dependencies: 232
-- Name: admin_notification_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_notification_templates_id_seq OWNED BY public.admin_notification_templates.id;


--
-- TOC entry 233 (class 1259 OID 93073)
-- Name: admin_notification_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_notification_types (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_notification_types OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 93079)
-- Name: admin_notification_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_notification_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_notification_types_id_seq OWNER TO postgres;

--
-- TOC entry 7644 (class 0 OID 0)
-- Dependencies: 234
-- Name: admin_notification_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_notification_types_id_seq OWNED BY public.admin_notification_types.id;


--
-- TOC entry 235 (class 1259 OID 93081)
-- Name: admin_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_permissions (
    id bigint NOT NULL,
    admin_feature_id bigint NOT NULL,
    admin_role_id bigint NOT NULL,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_permissions OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 93085)
-- Name: admin_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_permissions_id_seq OWNER TO postgres;

--
-- TOC entry 7645 (class 0 OID 0)
-- Dependencies: 236
-- Name: admin_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_permissions_id_seq OWNED BY public.admin_permissions.id;


--
-- TOC entry 237 (class 1259 OID 93087)
-- Name: admin_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_roles (
    id bigint NOT NULL,
    name character varying NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_roles OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 93093)
-- Name: admin_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_roles_id_seq OWNER TO postgres;

--
-- TOC entry 7646 (class 0 OID 0)
-- Dependencies: 238
-- Name: admin_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_roles_id_seq OWNED BY public.admin_roles.id;


--
-- TOC entry 239 (class 1259 OID 93095)
-- Name: admin_slack_notification_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_slack_notification_logs (
    id bigint NOT NULL,
    slack_user_ids character varying,
    channel_ids character varying,
    text character varying,
    ok boolean,
    error character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    admin_user_id bigint
);


ALTER TABLE public.admin_slack_notification_logs OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 93101)
-- Name: admin_slack_notification_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_slack_notification_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_slack_notification_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7647 (class 0 OID 0)
-- Dependencies: 240
-- Name: admin_slack_notification_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_slack_notification_logs_id_seq OWNED BY public.admin_slack_notification_logs.id;


--
-- TOC entry 241 (class 1259 OID 93103)
-- Name: admin_user_col_pref_user_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_user_col_pref_user_activities (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    visit_token boolean DEFAULT false,
    visitor_token boolean DEFAULT false,
    user_id boolean DEFAULT false,
    ip boolean DEFAULT false,
    user_agent boolean DEFAULT false,
    referrer boolean DEFAULT false,
    referring_domain boolean DEFAULT false,
    landing_page boolean DEFAULT false,
    browser boolean DEFAULT false,
    os boolean DEFAULT false,
    device_type boolean DEFAULT false,
    country boolean DEFAULT false,
    region boolean DEFAULT false,
    city boolean DEFAULT false,
    latitude boolean DEFAULT false,
    longitude boolean DEFAULT false,
    utm_source boolean DEFAULT false,
    utm_medium boolean DEFAULT false,
    utm_term boolean DEFAULT false,
    utm_content boolean DEFAULT false,
    utm_campaign boolean DEFAULT false,
    app_version boolean DEFAULT false,
    os_version boolean DEFAULT false,
    platform boolean DEFAULT false,
    started_at boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    company_name boolean DEFAULT false,
    account_id boolean DEFAULT false
);


ALTER TABLE public.admin_user_col_pref_user_activities OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 93133)
-- Name: admin_user_col_pref_user_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_user_col_pref_user_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_user_col_pref_user_activities_id_seq OWNER TO postgres;

--
-- TOC entry 7648 (class 0 OID 0)
-- Dependencies: 242
-- Name: admin_user_col_pref_user_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_user_col_pref_user_activities_id_seq OWNED BY public.admin_user_col_pref_user_activities.id;


--
-- TOC entry 243 (class 1259 OID 93135)
-- Name: admin_user_column_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_user_column_preferences (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    account_id boolean DEFAULT false,
    account_name boolean DEFAULT false,
    carrier_id boolean DEFAULT true,
    status boolean DEFAULT false,
    location boolean DEFAULT false,
    sales_rep boolean DEFAULT false,
    account_manager boolean DEFAULT false,
    date boolean DEFAULT false,
    email boolean DEFAULT true,
    phone boolean DEFAULT true,
    activation_time boolean DEFAULT true,
    internal boolean DEFAULT true,
    company_name boolean DEFAULT false,
    timezone boolean DEFAULT true,
    address boolean DEFAULT true,
    city boolean DEFAULT true,
    state boolean DEFAULT true,
    zip boolean DEFAULT true,
    is_mfa_enabled boolean DEFAULT true,
    invoice boolean DEFAULT true,
    rebill boolean DEFAULT true,
    rebill_amount boolean DEFAULT true,
    credit_limit boolean DEFAULT true,
    rebill_failure boolean DEFAULT true,
    cash_balance boolean DEFAULT true,
    promo_balance boolean DEFAULT true,
    total_balance boolean DEFAULT true,
    total_spend boolean DEFAULT false,
    total_campaigns boolean DEFAULT true,
    products boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    enterprise boolean DEFAULT false,
    call_transcription boolean DEFAULT true,
    campaign_status boolean DEFAULT false,
    account_pace boolean DEFAULT false
);


ALTER TABLE public.admin_user_column_preferences OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 93172)
-- Name: admin_user_column_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_user_column_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_user_column_preferences_id_seq OWNER TO postgres;

--
-- TOC entry 7649 (class 0 OID 0)
-- Dependencies: 244
-- Name: admin_user_column_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_user_column_preferences_id_seq OWNED BY public.admin_user_column_preferences.id;


--
-- TOC entry 245 (class 1259 OID 93174)
-- Name: admin_user_customize_column_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_user_customize_column_orders (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    admin_clients text,
    user_activity text,
    admin_analytics text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_user_customize_column_orders OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 93180)
-- Name: admin_user_customize_column_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_user_customize_column_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_user_customize_column_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7650 (class 0 OID 0)
-- Dependencies: 246
-- Name: admin_user_customize_column_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_user_customize_column_orders_id_seq OWNED BY public.admin_user_customize_column_orders.id;


--
-- TOC entry 247 (class 1259 OID 93182)
-- Name: admin_user_notifications_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_user_notifications_preferences (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    admin_notification_type_id bigint NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_email_notification boolean DEFAULT false,
    is_slack_notification boolean DEFAULT false
);


ALTER TABLE public.admin_user_notifications_preferences OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 93188)
-- Name: admin_user_notifications_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_user_notifications_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_user_notifications_preferences_id_seq OWNER TO postgres;

--
-- TOC entry 7651 (class 0 OID 0)
-- Dependencies: 248
-- Name: admin_user_notifications_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_user_notifications_preferences_id_seq OWNED BY public.admin_user_notifications_preferences.id;


--
-- TOC entry 249 (class 1259 OID 93190)
-- Name: admin_user_smart_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_user_smart_views (
    id bigint NOT NULL,
    name character varying NOT NULL,
    admin_user_id bigint NOT NULL,
    smart_view_filters jsonb,
    smart_view_group_bys jsonb,
    discarded_at timestamp(6) without time zone,
    product_type_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_user_smart_views OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 93196)
-- Name: admin_user_smart_views_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_user_smart_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_user_smart_views_id_seq OWNER TO postgres;

--
-- TOC entry 7652 (class 0 OID 0)
-- Dependencies: 250
-- Name: admin_user_smart_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_user_smart_views_id_seq OWNED BY public.admin_user_smart_views.id;


--
-- TOC entry 251 (class 1259 OID 93198)
-- Name: admin_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp(6) without time zone,
    first_name character varying,
    last_name character varying,
    phone character varying,
    extension character varying,
    avatar character varying,
    close_io_user_id character varying,
    access_role character varying,
    assign_accounts boolean DEFAULT false NOT NULL,
    assign_leads boolean DEFAULT false NOT NULL,
    last_assignment timestamp(6) without time zone,
    job_title character varying,
    team_lead boolean DEFAULT false NOT NULL,
    slack_user_id character varying,
    department character varying,
    manager_id bigint,
    team_lead_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    status character varying,
    is_mfa_enabled boolean DEFAULT true,
    is_email_otp_enabled boolean DEFAULT true,
    otp_secret character varying
);


ALTER TABLE public.admin_users OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 93213)
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_users_id_seq OWNER TO postgres;

--
-- TOC entry 7653 (class 0 OID 0)
-- Dependencies: 252
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- TOC entry 253 (class 1259 OID 93215)
-- Name: ads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ads (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint,
    ad_name character varying,
    image character varying,
    ad_image_url text,
    brand_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    carriers character varying
);


ALTER TABLE public.ads OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 93221)
-- Name: ads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ads_id_seq OWNER TO postgres;

--
-- TOC entry 7654 (class 0 OID 0)
-- Dependencies: 254
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ads_id_seq OWNED BY public.ads.id;


--
-- TOC entry 255 (class 1259 OID 93223)
-- Name: agent_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_profiles (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    name character varying,
    address character varying,
    carrier character varying,
    city character varying,
    phone_num character varying,
    state character varying,
    zip_code bigint,
    hours_of_operation text,
    languages character varying[] DEFAULT '{}'::character varying[],
    agency_info text,
    profile_img character varying,
    company_logo character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    terms_of_service character varying,
    privacy_policy character varying,
    products_offered text,
    brand_id bigint,
    show_popup boolean DEFAULT true,
    popup_waiting_duration integer DEFAULT 5,
    tcpa_content text
);


ALTER TABLE public.agent_profiles OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 93232)
-- Name: agent_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agent_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.agent_profiles_id_seq OWNER TO postgres;

--
-- TOC entry 7655 (class 0 OID 0)
-- Dependencies: 256
-- Name: agent_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agent_profiles_id_seq OWNED BY public.agent_profiles.id;


--
-- TOC entry 257 (class 1259 OID 93234)
-- Name: ahoy_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ahoy_events (
    id bigint NOT NULL,
    visit_id bigint,
    user_id bigint,
    name character varying,
    properties jsonb,
    "time" timestamp(6) without time zone,
    account_id bigint
);


ALTER TABLE public.ahoy_events OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 93240)
-- Name: ahoy_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ahoy_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ahoy_events_id_seq OWNER TO postgres;

--
-- TOC entry 7656 (class 0 OID 0)
-- Dependencies: 258
-- Name: ahoy_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ahoy_events_id_seq OWNED BY public.ahoy_events.id;


--
-- TOC entry 259 (class 1259 OID 93242)
-- Name: ahoy_visits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ahoy_visits (
    id bigint NOT NULL,
    visit_token character varying,
    visitor_token character varying,
    user_id bigint,
    ip character varying,
    user_agent text,
    referrer text,
    referring_domain character varying,
    landing_page text,
    browser character varying,
    os character varying,
    device_type character varying,
    country character varying,
    region character varying,
    city character varying,
    latitude double precision,
    longitude double precision,
    utm_source character varying,
    utm_medium character varying,
    utm_term character varying,
    utm_content character varying,
    utm_campaign character varying,
    app_version character varying,
    os_version character varying,
    platform character varying,
    started_at timestamp(6) without time zone
);


ALTER TABLE public.ahoy_visits OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 93248)
-- Name: ahoy_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ahoy_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ahoy_visits_id_seq OWNER TO postgres;

--
-- TOC entry 7657 (class 0 OID 0)
-- Dependencies: 260
-- Name: ahoy_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ahoy_visits_id_seq OWNED BY public.ahoy_visits.id;


--
-- TOC entry 261 (class 1259 OID 93250)
-- Name: analytic_pixel_columns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.analytic_pixel_columns (
    id bigint NOT NULL,
    click_conversion_pixel_id bigint NOT NULL,
    disp_count boolean DEFAULT true,
    disp_cvr boolean DEFAULT true,
    disp_cpa boolean DEFAULT true,
    disp_rev boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    disp_leads_count boolean DEFAULT true,
    disp_leads_cvr boolean DEFAULT true,
    disp_leads_cpa boolean DEFAULT true,
    disp_leads_rev boolean DEFAULT true,
    disp_calls_count boolean DEFAULT true,
    disp_calls_cvr boolean DEFAULT true,
    disp_calls_cpa boolean DEFAULT true,
    disp_calls_rev boolean DEFAULT true
);


ALTER TABLE public.analytic_pixel_columns OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 93265)
-- Name: analytic_pixel_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.analytic_pixel_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.analytic_pixel_columns_id_seq OWNER TO postgres;

--
-- TOC entry 7658 (class 0 OID 0)
-- Dependencies: 262
-- Name: analytic_pixel_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.analytic_pixel_columns_id_seq OWNED BY public.analytic_pixel_columns.id;


--
-- TOC entry 263 (class 1259 OID 93267)
-- Name: analytics_export_uploads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.analytics_export_uploads (
    id bigint NOT NULL,
    analytics_export_id bigint NOT NULL,
    file character varying,
    token character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.analytics_export_uploads OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 93273)
-- Name: analytics_export_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.analytics_export_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.analytics_export_uploads_id_seq OWNER TO postgres;

--
-- TOC entry 7659 (class 0 OID 0)
-- Dependencies: 264
-- Name: analytics_export_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.analytics_export_uploads_id_seq OWNED BY public.analytics_export_uploads.id;


--
-- TOC entry 265 (class 1259 OID 93275)
-- Name: analytics_exports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.analytics_exports (
    id bigint NOT NULL,
    product_type_id bigint NOT NULL,
    admin_user_id bigint,
    account_id bigint NOT NULL,
    user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    export_params text
);


ALTER TABLE public.analytics_exports OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 93281)
-- Name: analytics_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.analytics_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.analytics_exports_id_seq OWNER TO postgres;

--
-- TOC entry 7660 (class 0 OID 0)
-- Dependencies: 266
-- Name: analytics_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.analytics_exports_id_seq OWNED BY public.analytics_exports.id;


--
-- TOC entry 267 (class 1259 OID 93283)
-- Name: api_profiling_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_profiling_tags (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.api_profiling_tags OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 93290)
-- Name: api_profiling_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_profiling_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.api_profiling_tags_id_seq OWNER TO postgres;

--
-- TOC entry 7661 (class 0 OID 0)
-- Dependencies: 268
-- Name: api_profiling_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_profiling_tags_id_seq OWNED BY public.api_profiling_tags.id;


--
-- TOC entry 269 (class 1259 OID 93292)
-- Name: api_timing_api_profiling_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_timing_api_profiling_tags (
    id bigint NOT NULL,
    api_timing_id bigint NOT NULL,
    api_profiling_tag_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.api_timing_api_profiling_tags OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 93296)
-- Name: api_timing_api_profiling_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_timing_api_profiling_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.api_timing_api_profiling_tags_id_seq OWNER TO postgres;

--
-- TOC entry 7662 (class 0 OID 0)
-- Dependencies: 270
-- Name: api_timing_api_profiling_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_timing_api_profiling_tags_id_seq OWNED BY public.api_timing_api_profiling_tags.id;


--
-- TOC entry 271 (class 1259 OID 93298)
-- Name: api_timings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_timings (
    id bigint NOT NULL,
    controller_name character varying,
    action_name character varying,
    elapsed_time integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    request_params jsonb,
    api_status character varying,
    request_id character varying,
    db_runtime integer,
    request_header jsonb,
    response jsonb,
    jira_key character varying
);


ALTER TABLE public.api_timings OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 93304)
-- Name: api_timings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_timings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.api_timings_id_seq OWNER TO postgres;

--
-- TOC entry 7663 (class 0 OID 0)
-- Dependencies: 272
-- Name: api_timings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_timings_id_seq OWNED BY public.api_timings.id;


--
-- TOC entry 273 (class 1259 OID 93306)
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 93312)
-- Name: assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignments (
    id bigint NOT NULL,
    role_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    membership_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.assignments OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 93315)
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assignments_id_seq OWNER TO postgres;

--
-- TOC entry 7664 (class 0 OID 0)
-- Dependencies: 275
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- TOC entry 276 (class 1259 OID 93317)
-- Name: automation_test_execution_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.automation_test_execution_results (
    id bigint NOT NULL,
    semaphore_workflow_id character varying NOT NULL,
    test_suites_count integer DEFAULT 0 NOT NULL,
    test_suites_failed integer DEFAULT 0 NOT NULL,
    "time" double precision DEFAULT 0.0 NOT NULL,
    reports_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.automation_test_execution_results OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 93326)
-- Name: automation_test_execution_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.automation_test_execution_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.automation_test_execution_results_id_seq OWNER TO postgres;

--
-- TOC entry 7665 (class 0 OID 0)
-- Dependencies: 277
-- Name: automation_test_execution_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.automation_test_execution_results_id_seq OWNED BY public.automation_test_execution_results.id;


--
-- TOC entry 278 (class 1259 OID 93328)
-- Name: automation_test_suite_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.automation_test_suite_results (
    id bigint NOT NULL,
    automation_test_execution_result_id bigint NOT NULL,
    test_suite_name character varying NOT NULL,
    tests_count integer DEFAULT 0 NOT NULL,
    failures_count integer DEFAULT 0 NOT NULL,
    skipped_count integer DEFAULT 0 NOT NULL,
    errors_count integer DEFAULT 0 NOT NULL,
    "time" double precision DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.automation_test_suite_results OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 93339)
-- Name: automation_test_suite_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.automation_test_suite_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.automation_test_suite_results_id_seq OWNER TO postgres;

--
-- TOC entry 7666 (class 0 OID 0)
-- Dependencies: 279
-- Name: automation_test_suite_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.automation_test_suite_results_id_seq OWNED BY public.automation_test_suite_results.id;


--
-- TOC entry 280 (class 1259 OID 93341)
-- Name: bill_com_invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bill_com_invoices (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    brand_id bigint NOT NULL,
    invoice_id bigint,
    bill_com_id character varying NOT NULL,
    active boolean,
    created_by character varying,
    customer_id character varying,
    invoice_number character varying,
    invoice_date date,
    due_date date,
    amount numeric(20,2),
    outstanding_balance numeric(20,2),
    payment_status character varying,
    sales_rep character varying,
    gl_posting_date date,
    bill_com_created_at timestamp(6) without time zone,
    bill_com_updated_at timestamp(6) without time zone,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_sent_at timestamp(6) without time zone,
    email_delivery_option character varying,
    mail_delivery_option character varying
);


ALTER TABLE public.bill_com_invoices OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 93347)
-- Name: bill_com_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bill_com_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bill_com_invoices_id_seq OWNER TO postgres;

--
-- TOC entry 7667 (class 0 OID 0)
-- Dependencies: 281
-- Name: bill_com_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bill_com_invoices_id_seq OWNED BY public.bill_com_invoices.id;


--
-- TOC entry 282 (class 1259 OID 93349)
-- Name: bill_com_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bill_com_items (
    id bigint NOT NULL,
    lead_type_id integer,
    product_type_id integer,
    client_type_id integer,
    item_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.bill_com_items OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 93355)
-- Name: bill_com_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bill_com_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bill_com_items_id_seq OWNER TO postgres;

--
-- TOC entry 7668 (class 0 OID 0)
-- Dependencies: 283
-- Name: bill_com_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bill_com_items_id_seq OWNED BY public.bill_com_items.id;


--
-- TOC entry 284 (class 1259 OID 93357)
-- Name: bill_com_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bill_com_sessions (
    id bigint NOT NULL,
    session_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    cookies text
);


ALTER TABLE public.bill_com_sessions OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 93363)
-- Name: bill_com_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bill_com_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bill_com_sessions_id_seq OWNER TO postgres;

--
-- TOC entry 7669 (class 0 OID 0)
-- Dependencies: 285
-- Name: bill_com_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bill_com_sessions_id_seq OWNED BY public.bill_com_sessions.id;


--
-- TOC entry 286 (class 1259 OID 93365)
-- Name: billing_setting_invoice_changes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.billing_setting_invoice_changes (
    id bigint NOT NULL,
    billing_setting_id bigint,
    account_id bigint,
    changed_to character varying,
    created_at timestamp(6) without time zone
);


ALTER TABLE public.billing_setting_invoice_changes OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 93371)
-- Name: billing_setting_invoice_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.billing_setting_invoice_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.billing_setting_invoice_changes_id_seq OWNER TO postgres;

--
-- TOC entry 7670 (class 0 OID 0)
-- Dependencies: 287
-- Name: billing_setting_invoice_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.billing_setting_invoice_changes_id_seq OWNED BY public.billing_setting_invoice_changes.id;


--
-- TOC entry 288 (class 1259 OID 93373)
-- Name: billing_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.billing_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    rebill smallint DEFAULT 1,
    rebill_amount numeric(12,2) DEFAULT 250.0,
    invoice smallint DEFAULT 0,
    credit_limit integer,
    rebill_failure integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    client_secret text,
    stripe_customer_id character varying,
    stripe_setup_intent_id text,
    rebill_threshold numeric(12,2) DEFAULT 50.0,
    is_update_card_pending boolean DEFAULT true,
    pending_stripe_setup_intent_id character varying DEFAULT 'null'::character varying,
    pending_client_secret character varying DEFAULT 'null'::character varying,
    card_last4 integer,
    card_brand character varying(16),
    card_expiry_month smallint,
    card_expiry_year integer,
    billing_zip bigint,
    account_id bigint,
    payment_term_id bigint,
    bill_com_cust_id character varying,
    billing_setting_changed boolean DEFAULT false,
    platform_management_fee numeric(12,2),
    min_spend numeric(12,2),
    transaction_fee numeric(12,2),
    close_com_custom_obj_id character varying
);


ALTER TABLE public.billing_settings OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 93388)
-- Name: billing_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.billing_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.billing_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7671 (class 0 OID 0)
-- Dependencies: 289
-- Name: billing_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.billing_settings_id_seq OWNED BY public.billing_settings.id;


--
-- TOC entry 290 (class 1259 OID 93390)
-- Name: brands; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.brands (
    id bigint NOT NULL,
    name character varying,
    account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    active boolean DEFAULT true
);


ALTER TABLE public.brands OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 93397)
-- Name: brands_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.brands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.brands_id_seq OWNER TO postgres;

--
-- TOC entry 7672 (class 0 OID 0)
-- Dependencies: 291
-- Name: brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.brands_id_seq OWNED BY public.brands.id;


--
-- TOC entry 292 (class 1259 OID 93399)
-- Name: call_ad_group_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_ad_group_settings (
    id bigint NOT NULL,
    transfer_number character varying,
    discarded_at timestamp(6) without time zone,
    ad_group_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_ad_group_settings OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 93405)
-- Name: call_ad_group_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_ad_group_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_ad_group_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7673 (class 0 OID 0)
-- Dependencies: 293
-- Name: call_ad_group_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_ad_group_settings_id_seq OWNED BY public.call_ad_group_settings.id;


--
-- TOC entry 294 (class 1259 OID 93407)
-- Name: call_campaign_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_campaign_settings (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    account_id bigint NOT NULL,
    billable_duration integer DEFAULT 5,
    transfer_number character varying,
    call_recording boolean DEFAULT true NOT NULL,
    show_customer_caller_id boolean DEFAULT false NOT NULL,
    ivr boolean DEFAULT false NOT NULL,
    ivr_route character varying,
    tracking_number character varying,
    data_release_duration integer DEFAULT 5,
    concurrency_cap integer DEFAULT 1,
    pausable boolean,
    transfer_type integer DEFAULT 0,
    pre_transfer_script text,
    transfer_script text,
    overflow boolean DEFAULT false,
    email_opted_out boolean DEFAULT false NOT NULL,
    call_transcription boolean DEFAULT true,
    call_origination_type integer,
    conv_rate numeric(5,2) DEFAULT 100.0,
    emails text[] DEFAULT '{}'::text[],
    upstream_type text[] DEFAULT '{}'::text[]
);


ALTER TABLE public.call_campaign_settings OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 93426)
-- Name: call_campaign_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_campaign_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_campaign_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7674 (class 0 OID 0)
-- Dependencies: 295
-- Name: call_campaign_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_campaign_settings_id_seq OWNED BY public.call_campaign_settings.id;


--
-- TOC entry 296 (class 1259 OID 93428)
-- Name: call_listings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_listings (
    id bigint NOT NULL,
    call_ping_id integer,
    campaign_id integer,
    ad_group_id integer,
    brand_id integer,
    account_id integer,
    carrier_id integer,
    license_num character varying,
    transfer_number character varying,
    tracking_number character varying,
    billable_duration integer,
    payout numeric(10,2),
    est_payout numeric(10,2),
    post_payout numeric(10,2),
    bid_id character varying,
    "position" integer,
    selected boolean,
    de_duped boolean,
    excluded boolean,
    transferred boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    buyer character varying,
    ping_post boolean DEFAULT false,
    pp_ping_id character varying,
    pp_bid_id character varying
);


ALTER TABLE public.call_listings OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 93435)
-- Name: call_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_listings_id_seq OWNER TO postgres;

--
-- TOC entry 7675 (class 0 OID 0)
-- Dependencies: 297
-- Name: call_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_listings_id_seq OWNED BY public.call_listings.id;


--
-- TOC entry 298 (class 1259 OID 93437)
-- Name: call_opportunities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_opportunities (
    id bigint NOT NULL,
    call_ping_id integer,
    campaign_id integer,
    ad_group_id integer,
    brand_id integer,
    account_id integer,
    payout numeric(7,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_opportunities OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 93440)
-- Name: call_opportunities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_opportunities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_opportunities_id_seq OWNER TO postgres;

--
-- TOC entry 7676 (class 0 OID 0)
-- Dependencies: 299
-- Name: call_opportunities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_opportunities_id_seq OWNED BY public.call_opportunities.id;


--
-- TOC entry 300 (class 1259 OID 93442)
-- Name: call_panels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_panels (
    id bigint NOT NULL,
    click_ping_id integer,
    advertiser character varying,
    "position" integer,
    payout numeric(8,2),
    est_payout numeric(8,2),
    overflow boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_panels OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 93448)
-- Name: call_panels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_panels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_panels_id_seq OWNER TO postgres;

--
-- TOC entry 7677 (class 0 OID 0)
-- Dependencies: 301
-- Name: call_panels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_panels_id_seq OWNED BY public.call_panels.id;


--
-- TOC entry 302 (class 1259 OID 93450)
-- Name: call_ping_debug_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_ping_debug_logs (
    id bigint NOT NULL,
    call_ping_id integer,
    log text,
    response_time_ms integer,
    num_listings integer,
    token character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_ping_debug_logs OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 93456)
-- Name: call_ping_debug_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_ping_debug_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_ping_debug_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7678 (class 0 OID 0)
-- Dependencies: 303
-- Name: call_ping_debug_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_ping_debug_logs_id_seq OWNED BY public.call_ping_debug_logs.id;


--
-- TOC entry 304 (class 1259 OID 93458)
-- Name: call_ping_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_ping_details (
    id bigint NOT NULL,
    call_ping_id integer,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age integer,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    phone character varying,
    email character varying,
    city character varying,
    county character varying,
    tobacco boolean,
    major_health_conditions boolean,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    jornaya_lead_id character varying,
    trusted_form_token character varying,
    col1 character varying,
    col2 character varying,
    col3 character varying,
    col4 character varying,
    col5 character varying,
    col6 character varying,
    col7 character varying,
    col8 character varying,
    col9 character varying,
    col10 character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_ping_details OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 93464)
-- Name: call_ping_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_ping_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_ping_details_id_seq OWNER TO postgres;

--
-- TOC entry 7679 (class 0 OID 0)
-- Dependencies: 305
-- Name: call_ping_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_ping_details_id_seq OWNED BY public.call_ping_details.id;


--
-- TOC entry 306 (class 1259 OID 93466)
-- Name: call_ping_matches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_ping_matches (
    id bigint NOT NULL,
    call_ping_id integer,
    account_id integer,
    campaign_id integer,
    ad_group_id integer,
    brand_id integer,
    ad_group_active boolean,
    payout numeric(10,2),
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_ping_matches OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 93469)
-- Name: call_ping_matches_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_ping_matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_ping_matches_id_seq OWNER TO postgres;

--
-- TOC entry 7680 (class 0 OID 0)
-- Dependencies: 307
-- Name: call_ping_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_ping_matches_id_seq OWNED BY public.call_ping_matches.id;


--
-- TOC entry 308 (class 1259 OID 93471)
-- Name: call_pings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_pings (
    id bigint NOT NULL,
    partner_id character varying,
    lead_type_id integer,
    aid character varying,
    cid character varying,
    sid character varying,
    ks character varying,
    session_id character varying,
    zip character varying,
    state character varying,
    device_type character varying,
    source_type_id integer,
    form_type_id integer,
    lead_data text,
    total_opportunities integer,
    total_listings integer,
    total_revenue numeric(7,2),
    total_cost numeric(7,2),
    uid character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_pings OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 93477)
-- Name: call_pings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_pings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_pings_id_seq OWNER TO postgres;

--
-- TOC entry 7681 (class 0 OID 0)
-- Dependencies: 309
-- Name: call_pings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_pings_id_seq OWNED BY public.call_pings.id;


--
-- TOC entry 310 (class 1259 OID 93479)
-- Name: call_post_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_post_details (
    id bigint NOT NULL,
    call_post_id integer,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age integer,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    phone character varying,
    email character varying,
    city character varying,
    county character varying,
    tobacco boolean,
    major_health_conditions boolean,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    jornaya_lead_id character varying,
    trusted_form_token character varying,
    col1 character varying,
    col2 character varying,
    col3 character varying,
    col4 character varying,
    col5 character varying,
    col6 character varying,
    col7 character varying,
    col8 character varying,
    col9 character varying,
    col10 character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_post_details OWNER TO postgres;

--
-- TOC entry 311 (class 1259 OID 93485)
-- Name: call_post_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_post_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_post_details_id_seq OWNER TO postgres;

--
-- TOC entry 7682 (class 0 OID 0)
-- Dependencies: 311
-- Name: call_post_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_post_details_id_seq OWNED BY public.call_post_details.id;


--
-- TOC entry 312 (class 1259 OID 93487)
-- Name: call_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_posts (
    id bigint NOT NULL,
    call_ping_id integer,
    partner_id character varying,
    lead_type_id integer,
    zip character varying,
    state character varying,
    accepted boolean,
    cost numeric(10,2),
    revenue numeric(10,2),
    refunded boolean,
    data text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    uid character varying
);


ALTER TABLE public.call_posts OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 93493)
-- Name: call_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_posts_id_seq OWNER TO postgres;

--
-- TOC entry 7683 (class 0 OID 0)
-- Dependencies: 313
-- Name: call_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_posts_id_seq OWNED BY public.call_posts.id;


--
-- TOC entry 314 (class 1259 OID 93495)
-- Name: call_prices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_prices (
    id bigint NOT NULL,
    price numeric,
    lead_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_prices OWNER TO postgres;

--
-- TOC entry 315 (class 1259 OID 93501)
-- Name: call_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_prices_id_seq OWNER TO postgres;

--
-- TOC entry 7684 (class 0 OID 0)
-- Dependencies: 315
-- Name: call_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_prices_id_seq OWNED BY public.call_prices.id;


--
-- TOC entry 316 (class 1259 OID 93503)
-- Name: call_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_results (
    id bigint NOT NULL,
    call_ping_id integer,
    account_id integer,
    campaign_id integer,
    brand_id integer,
    ad_group_id integer,
    session_id character varying,
    partner_id character varying,
    lead_type_id integer,
    aid character varying,
    cid character varying,
    sid character varying,
    ks character varying,
    zip character varying,
    state character varying,
    device_type character varying,
    source_type_id integer,
    active_source boolean,
    form_type_id integer,
    carrier_id integer,
    license_num character varying,
    transfer_number character varying,
    tracking_number character varying,
    billable_duration integer,
    payout numeric(10,2),
    est_payout numeric(10,2),
    post_payout numeric(10,2),
    bid_id character varying,
    "position" integer,
    selected boolean,
    de_duped boolean,
    excluded boolean,
    transferred boolean,
    buyer character varying,
    ping_post boolean,
    pp_ping_id character varying,
    pp_bid_id character varying,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    charged boolean,
    charged_price numeric(10,2),
    quote_call_id integer,
    call_duration integer,
    match boolean,
    opportunity boolean,
    listing boolean,
    mobile boolean,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age integer,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    phone character varying,
    email character varying,
    city character varying,
    county character varying,
    tobacco boolean,
    major_health_conditions boolean,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    ip_address character varying,
    disqualification_reason character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_results OWNER TO postgres;

--
-- TOC entry 317 (class 1259 OID 93509)
-- Name: call_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_results_id_seq OWNER TO postgres;

--
-- TOC entry 7685 (class 0 OID 0)
-- Dependencies: 317
-- Name: call_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_results_id_seq OWNED BY public.call_results.id;


--
-- TOC entry 318 (class 1259 OID 93511)
-- Name: call_transcription_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_transcription_rules (
    id bigint NOT NULL,
    phrases character varying[] DEFAULT '{}'::character varying[],
    speaker character varying DEFAULT ''::character varying,
    rule_type character varying,
    mentioned boolean,
    time_range_time_frame character varying,
    time_range_value bigint,
    time_range_type character varying,
    threshold_value bigint,
    threshold_time_type character varying,
    sentiment character varying,
    call_transcription_topic_id bigint,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_transcription_rules OWNER TO postgres;

--
-- TOC entry 319 (class 1259 OID 93519)
-- Name: call_transcription_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_transcription_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_transcription_rules_id_seq OWNER TO postgres;

--
-- TOC entry 7686 (class 0 OID 0)
-- Dependencies: 319
-- Name: call_transcription_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_transcription_rules_id_seq OWNED BY public.call_transcription_rules.id;


--
-- TOC entry 320 (class 1259 OID 93521)
-- Name: call_transcription_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_transcription_settings (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    active boolean DEFAULT false,
    num_categories bigint DEFAULT 5,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.call_transcription_settings OWNER TO postgres;

--
-- TOC entry 321 (class 1259 OID 93526)
-- Name: call_transcription_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_transcription_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_transcription_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7687 (class 0 OID 0)
-- Dependencies: 321
-- Name: call_transcription_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_transcription_settings_id_seq OWNED BY public.call_transcription_settings.id;


--
-- TOC entry 322 (class 1259 OID 93528)
-- Name: call_transcription_topics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_transcription_topics (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    topic_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.call_transcription_topics OWNER TO postgres;

--
-- TOC entry 323 (class 1259 OID 93534)
-- Name: call_transcription_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.call_transcription_topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.call_transcription_topics_id_seq OWNER TO postgres;

--
-- TOC entry 7688 (class 0 OID 0)
-- Dependencies: 323
-- Name: call_transcription_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.call_transcription_topics_id_seq OWNED BY public.call_transcription_topics.id;


--
-- TOC entry 324 (class 1259 OID 93536)
-- Name: calls_customize_columns_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.calls_customize_columns_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    call_name integer DEFAULT 0,
    call_phone integer DEFAULT 0,
    call_duration integer DEFAULT 0,
    call_state integer DEFAULT 0,
    call_received integer DEFAULT 0,
    call_recording integer DEFAULT 0,
    call_insured integer DEFAULT 0,
    call_address integer DEFAULT 0,
    call_zip_code integer DEFAULT 0,
    call_city integer DEFAULT 0,
    call_vehicles integer DEFAULT 0,
    call_drivers integer DEFAULT 0,
    call_lead_type integer DEFAULT 0,
    call_campaign_name integer DEFAULT 0,
    call_status integer DEFAULT 0,
    status integer DEFAULT 0,
    cost integer DEFAULT 0,
    profile integer DEFAULT 0,
    transfer_type integer DEFAULT 0,
    duplicate integer DEFAULT 0,
    call_refund_status integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    aid integer DEFAULT 0,
    cid integer DEFAULT 0
);


ALTER TABLE public.calls_customize_columns_orders OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 93562)
-- Name: calls_customize_columns_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.calls_customize_columns_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.calls_customize_columns_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7689 (class 0 OID 0)
-- Dependencies: 325
-- Name: calls_customize_columns_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.calls_customize_columns_orders_id_seq OWNED BY public.calls_customize_columns_orders.id;


--
-- TOC entry 326 (class 1259 OID 93564)
-- Name: calls_dashboard_customize_column_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.calls_dashboard_customize_column_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    opportunities integer DEFAULT 0,
    searches integer DEFAULT 0,
    total_calls integer DEFAULT 0,
    billable_calls integer DEFAULT 0,
    total_cost integer DEFAULT 0,
    avg_cpc integer DEFAULT 0,
    total_call_duration integer DEFAULT 0,
    avg_call_duration integer DEFAULT 0,
    insurance_type_opportunities integer DEFAULT 0,
    insurance_type_searches integer DEFAULT 0,
    insurance_type_total_calls integer DEFAULT 0,
    insurance_type_billable_calls integer DEFAULT 0,
    insurance_type_total_cost integer DEFAULT 0,
    insurance_type_avg_cpc integer DEFAULT 0,
    insurance_type_total_call_duration integer DEFAULT 0,
    insurance_type_avg_call_duration integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.calls_dashboard_customize_column_orders OWNER TO postgres;

--
-- TOC entry 327 (class 1259 OID 93583)
-- Name: calls_dashboard_customize_column_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.calls_dashboard_customize_column_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.calls_dashboard_customize_column_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7690 (class 0 OID 0)
-- Dependencies: 327
-- Name: calls_dashboard_customize_column_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.calls_dashboard_customize_column_orders_id_seq OWNED BY public.calls_dashboard_customize_column_orders.id;


--
-- TOC entry 328 (class 1259 OID 93585)
-- Name: campaign_ads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_ads (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    ad_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    platform character varying,
    discarded_at timestamp(6) without time zone,
    weight integer DEFAULT 100,
    weight_type character varying,
    active_weight integer DEFAULT 0
);


ALTER TABLE public.campaign_ads OWNER TO postgres;

--
-- TOC entry 329 (class 1259 OID 93593)
-- Name: campaign_ads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_ads_id_seq OWNER TO postgres;

--
-- TOC entry 7691 (class 0 OID 0)
-- Dependencies: 329
-- Name: campaign_ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_ads_id_seq OWNED BY public.campaign_ads.id;


--
-- TOC entry 330 (class 1259 OID 93595)
-- Name: campaign_bid_modifier_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_bid_modifier_groups (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    bid_percent integer,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.campaign_bid_modifier_groups OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 93598)
-- Name: campaign_bid_modifier_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_bid_modifier_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_bid_modifier_groups_id_seq OWNER TO postgres;

--
-- TOC entry 7692 (class 0 OID 0)
-- Dependencies: 331
-- Name: campaign_bid_modifier_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_bid_modifier_groups_id_seq OWNED BY public.campaign_bid_modifier_groups.id;


--
-- TOC entry 332 (class 1259 OID 93600)
-- Name: campaign_bid_modifiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_bid_modifiers (
    id bigint NOT NULL,
    filter_value character varying,
    include boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    campaign_bid_modifier_group_id bigint,
    campaign_id bigint NOT NULL,
    filter_value_min character varying,
    filter_value_max character varying,
    price numeric(20,2),
    weight integer,
    sf_filter_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    filter_value_array text[] DEFAULT '{}'::text[],
    accept_unknown boolean DEFAULT true
);


ALTER TABLE public.campaign_bid_modifiers OWNER TO postgres;

--
-- TOC entry 333 (class 1259 OID 93608)
-- Name: campaign_bid_modifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_bid_modifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_bid_modifiers_id_seq OWNER TO postgres;

--
-- TOC entry 7693 (class 0 OID 0)
-- Dependencies: 333
-- Name: campaign_bid_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_bid_modifiers_id_seq OWNED BY public.campaign_bid_modifiers.id;


--
-- TOC entry 334 (class 1259 OID 93610)
-- Name: campaign_budgets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_budgets (
    id bigint NOT NULL,
    dollar_budget numeric(20,2),
    volume_budget integer,
    campaign_id bigint NOT NULL,
    day_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.campaign_budgets OWNER TO postgres;

--
-- TOC entry 335 (class 1259 OID 93613)
-- Name: campaign_budgets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_budgets_id_seq OWNER TO postgres;

--
-- TOC entry 7694 (class 0 OID 0)
-- Dependencies: 335
-- Name: campaign_budgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_budgets_id_seq OWNED BY public.campaign_budgets.id;


--
-- TOC entry 336 (class 1259 OID 93615)
-- Name: campaign_call_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_call_posts (
    id bigint NOT NULL,
    cost_posted numeric(10,2),
    cost_charged numeric(10,2),
    data text,
    success boolean,
    error text,
    data_released boolean,
    campaign_id integer,
    account_id integer,
    brand_id integer,
    quote_call_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.campaign_call_posts OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 93621)
-- Name: campaign_call_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_call_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_call_posts_id_seq OWNER TO postgres;

--
-- TOC entry 7695 (class 0 OID 0)
-- Dependencies: 337
-- Name: campaign_call_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_call_posts_id_seq OWNED BY public.campaign_call_posts.id;


--
-- TOC entry 338 (class 1259 OID 93623)
-- Name: campaign_dashboard_colunm_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_dashboard_colunm_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    opportunities integer DEFAULT 0,
    searches integer DEFAULT 0,
    total_calls integer DEFAULT 0,
    billable_calls integer DEFAULT 0,
    total_cost integer DEFAULT 0,
    avg_cpc integer DEFAULT 0,
    total_call_duration integer DEFAULT 0,
    avg_call_duration integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.campaign_dashboard_colunm_orders OWNER TO postgres;

--
-- TOC entry 339 (class 1259 OID 93634)
-- Name: campaign_dashboard_colunm_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_dashboard_colunm_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_dashboard_colunm_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7696 (class 0 OID 0)
-- Dependencies: 339
-- Name: campaign_dashboard_colunm_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_dashboard_colunm_orders_id_seq OWNED BY public.campaign_dashboard_colunm_orders.id;


--
-- TOC entry 340 (class 1259 OID 93636)
-- Name: campaign_filter_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_filter_groups (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.campaign_filter_groups OWNER TO postgres;

--
-- TOC entry 341 (class 1259 OID 93639)
-- Name: campaign_filter_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_filter_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_filter_groups_id_seq OWNER TO postgres;

--
-- TOC entry 7697 (class 0 OID 0)
-- Dependencies: 341
-- Name: campaign_filter_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_filter_groups_id_seq OWNED BY public.campaign_filter_groups.id;


--
-- TOC entry 342 (class 1259 OID 93641)
-- Name: campaign_filter_packages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_filter_packages (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    filter_package_id bigint NOT NULL,
    price numeric(20,2),
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.campaign_filter_packages OWNER TO postgres;

--
-- TOC entry 343 (class 1259 OID 93644)
-- Name: campaign_filter_packages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_filter_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_filter_packages_id_seq OWNER TO postgres;

--
-- TOC entry 7698 (class 0 OID 0)
-- Dependencies: 343
-- Name: campaign_filter_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_filter_packages_id_seq OWNED BY public.campaign_filter_packages.id;


--
-- TOC entry 344 (class 1259 OID 93646)
-- Name: campaign_filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_filters (
    id bigint NOT NULL,
    filter_value character varying,
    include boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    campaign_filter_group_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    filter_value_min character varying,
    filter_value_max character varying,
    price numeric(20,2),
    sf_filter_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    accept_unknown boolean DEFAULT true,
    filter_value_array text[] DEFAULT '{}'::text[]
);


ALTER TABLE public.campaign_filters OWNER TO postgres;

--
-- TOC entry 345 (class 1259 OID 93654)
-- Name: campaign_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_filters_id_seq OWNER TO postgres;

--
-- TOC entry 7699 (class 0 OID 0)
-- Dependencies: 345
-- Name: campaign_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_filters_id_seq OWNED BY public.campaign_filters.id;


--
-- TOC entry 346 (class 1259 OID 93656)
-- Name: campaign_lead_integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_lead_integrations (
    id bigint NOT NULL,
    lead_integration_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    config text
);


ALTER TABLE public.campaign_lead_integrations OWNER TO postgres;

--
-- TOC entry 347 (class 1259 OID 93662)
-- Name: campaign_lead_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_lead_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_lead_integrations_id_seq OWNER TO postgres;

--
-- TOC entry 7700 (class 0 OID 0)
-- Dependencies: 347
-- Name: campaign_lead_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_lead_integrations_id_seq OWNED BY public.campaign_lead_integrations.id;


--
-- TOC entry 348 (class 1259 OID 93664)
-- Name: campaign_lead_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_lead_posts (
    id bigint NOT NULL,
    campaign_id integer,
    account_id integer,
    brand_id integer,
    cost_posted numeric(10,2),
    cost_charged numeric(10,2),
    data text,
    success boolean,
    error text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.campaign_lead_posts OWNER TO postgres;

--
-- TOC entry 349 (class 1259 OID 93670)
-- Name: campaign_lead_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_lead_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_lead_posts_id_seq OWNER TO postgres;

--
-- TOC entry 7701 (class 0 OID 0)
-- Dependencies: 349
-- Name: campaign_lead_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_lead_posts_id_seq OWNED BY public.campaign_lead_posts.id;


--
-- TOC entry 350 (class 1259 OID 93672)
-- Name: campaign_monthly_spends; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_monthly_spends (
    id bigint NOT NULL,
    campaign_id integer,
    account_id integer,
    year integer,
    month integer,
    dollar_amt numeric(12,2),
    units integer,
    discarded_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.campaign_monthly_spends OWNER TO postgres;

--
-- TOC entry 351 (class 1259 OID 93675)
-- Name: campaign_monthly_spends_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_monthly_spends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_monthly_spends_id_seq OWNER TO postgres;

--
-- TOC entry 7702 (class 0 OID 0)
-- Dependencies: 351
-- Name: campaign_monthly_spends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_monthly_spends_id_seq OWNED BY public.campaign_monthly_spends.id;


--
-- TOC entry 352 (class 1259 OID 93677)
-- Name: campaign_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_notes (
    id bigint NOT NULL,
    text text,
    campaign_id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.campaign_notes OWNER TO postgres;

--
-- TOC entry 353 (class 1259 OID 93683)
-- Name: campaign_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_notes_id_seq OWNER TO postgres;

--
-- TOC entry 7703 (class 0 OID 0)
-- Dependencies: 353
-- Name: campaign_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_notes_id_seq OWNED BY public.campaign_notes.id;


--
-- TOC entry 354 (class 1259 OID 93685)
-- Name: campaign_pixel_columns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_pixel_columns (
    id bigint NOT NULL,
    click_conversion_pixel_id bigint NOT NULL,
    disp_count boolean,
    disp_cvr boolean,
    disp_cpa boolean,
    disp_rev boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    disp_clicks_count boolean DEFAULT true,
    disp_clicks_cvr boolean DEFAULT true,
    disp_clicks_cpa boolean DEFAULT true,
    disp_clicks_rev boolean DEFAULT true,
    disp_leads_count boolean DEFAULT true,
    disp_leads_cvr boolean DEFAULT true,
    disp_leads_cpa boolean DEFAULT true,
    disp_leads_rev boolean DEFAULT true,
    disp_calls_count boolean DEFAULT true,
    disp_calls_cvr boolean DEFAULT true,
    disp_calls_cpa boolean DEFAULT true,
    disp_calls_rev boolean DEFAULT true
);


ALTER TABLE public.campaign_pixel_columns OWNER TO postgres;

--
-- TOC entry 355 (class 1259 OID 93700)
-- Name: campaign_pixel_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_pixel_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_pixel_columns_id_seq OWNER TO postgres;

--
-- TOC entry 7704 (class 0 OID 0)
-- Dependencies: 355
-- Name: campaign_pixel_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_pixel_columns_id_seq OWNED BY public.campaign_pixel_columns.id;


--
-- TOC entry 356 (class 1259 OID 93702)
-- Name: campaign_quote_funnels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_quote_funnels (
    id bigint NOT NULL,
    quote_funnel_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    weight integer,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.campaign_quote_funnels OWNER TO postgres;

--
-- TOC entry 357 (class 1259 OID 93705)
-- Name: campaign_quote_funnels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_quote_funnels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_quote_funnels_id_seq OWNER TO postgres;

--
-- TOC entry 7705 (class 0 OID 0)
-- Dependencies: 357
-- Name: campaign_quote_funnels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_quote_funnels_id_seq OWNED BY public.campaign_quote_funnels.id;


--
-- TOC entry 358 (class 1259 OID 93707)
-- Name: campaign_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_schedules (
    id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    h0 integer,
    h1 integer,
    h2 integer,
    h3 integer,
    h4 integer,
    h5 integer,
    h6 integer,
    h7 integer,
    h8 integer,
    h9 integer,
    h10 integer,
    h11 integer,
    h12 integer,
    h13 integer,
    h14 integer,
    h15 integer,
    h16 integer,
    h17 integer,
    h18 integer,
    h19 integer,
    h20 integer,
    h21 integer,
    h22 integer,
    h23 integer,
    campaign_id bigint NOT NULL,
    day_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    timezone character varying,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.campaign_schedules OWNER TO postgres;

--
-- TOC entry 359 (class 1259 OID 93714)
-- Name: campaign_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_schedules_id_seq OWNER TO postgres;

--
-- TOC entry 7706 (class 0 OID 0)
-- Dependencies: 359
-- Name: campaign_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_schedules_id_seq OWNED BY public.campaign_schedules.id;


--
-- TOC entry 360 (class 1259 OID 93716)
-- Name: campaign_source_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_source_settings (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    source_type_id bigint NOT NULL,
    weight integer,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "desc" character varying
);


ALTER TABLE public.campaign_source_settings OWNER TO postgres;

--
-- TOC entry 361 (class 1259 OID 93723)
-- Name: campaign_source_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_source_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_source_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7707 (class 0 OID 0)
-- Dependencies: 361
-- Name: campaign_source_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_source_settings_id_seq OWNED BY public.campaign_source_settings.id;


--
-- TOC entry 362 (class 1259 OID 93725)
-- Name: campaign_spends; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_spends (
    id bigint NOT NULL,
    dt date,
    campaign_id bigint NOT NULL,
    user_id bigint NOT NULL,
    dollar_amt numeric(12,2) DEFAULT 0.0,
    units integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.campaign_spends OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 93730)
-- Name: campaign_spends_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_spends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaign_spends_id_seq OWNER TO postgres;

--
-- TOC entry 7708 (class 0 OID 0)
-- Dependencies: 363
-- Name: campaign_spends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_spends_id_seq OWNED BY public.campaign_spends.id;


--
-- TOC entry 364 (class 1259 OID 93732)
-- Name: campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaigns (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lead_type_id bigint NOT NULL,
    product_type_id bigint NOT NULL,
    name character varying,
    active boolean,
    monthly_budget numeric(20,2),
    monthly_volume integer,
    is_campaign_level_tracking boolean,
    brand_id bigint NOT NULL,
    timezone character varying,
    discarded_at timestamp(6) without time zone,
    price_presentation boolean DEFAULT false,
    shared_lead_type boolean DEFAULT true,
    locked_price boolean DEFAULT false,
    base_price numeric(12,2) DEFAULT 0.0,
    min_price numeric(12,2),
    max_price numeric(12,2),
    allowable_return_perc integer DEFAULT 0,
    close_com_id character varying
);


ALTER TABLE public.campaigns OWNER TO postgres;

--
-- TOC entry 365 (class 1259 OID 93743)
-- Name: campaigns_customize_columns_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaigns_customize_columns_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    lead_type integer DEFAULT 0,
    daily_budget integer DEFAULT 0,
    monthly_budget integer DEFAULT 0,
    click_analytic_searches integer DEFAULT 0,
    click_analytic_impressions integer DEFAULT 0,
    click_analytic_clicks integer DEFAULT 0,
    click_analytic_cpc integer DEFAULT 0,
    click_analytic_total_payout integer DEFAULT 0,
    contribution_margin integer DEFAULT 0,
    profit integer DEFAULT 0,
    click_analytic_queries integer DEFAULT 0,
    is_lead_product integer DEFAULT 0,
    is_lead_type integer DEFAULT 0,
    is_lead_daily_limit integer DEFAULT 0,
    is_lead_monthly_limit integer DEFAULT 0,
    is_lead_inventory integer DEFAULT 0,
    is_lead_opportunities integer DEFAULT 0,
    is_lead_target_rate integer DEFAULT 0,
    is_lead_bids integer DEFAULT 0,
    is_lead_bid_rate integer DEFAULT 0,
    is_lead_posts integer DEFAULT 0,
    is_lead_accepted integer DEFAULT 0,
    is_lead_accept_rate integer DEFAULT 0,
    is_lead_avg_bid integer DEFAULT 0,
    is_lead_avg_cpl integer DEFAULT 0,
    is_lead_spend integer DEFAULT 0,
    is_call_product integer DEFAULT 0,
    is_call_type integer DEFAULT 0,
    is_call_daily_limit integer DEFAULT 0,
    is_call_monthly_limit integer DEFAULT 0,
    is_call_inventory integer DEFAULT 0,
    is_call_opportunities integer DEFAULT 0,
    is_call_target_rate integer DEFAULT 0,
    is_call_bids integer DEFAULT 0,
    is_call_bid_rate integer DEFAULT 0,
    is_call_transfers integer DEFAULT 0,
    is_call_accepted integer DEFAULT 0,
    is_call_accept_rate integer DEFAULT 0,
    is_call_avg_bid integer DEFAULT 0,
    is_call_avg_cpc integer DEFAULT 0,
    is_call_spend integer DEFAULT 0,
    is_call_avg_duration integer DEFAULT 0,
    is_lead_profit integer DEFAULT 0,
    is_lead_cm integer DEFAULT 0,
    is_call_profit integer DEFAULT 0,
    is_call_cm integer DEFAULT 0,
    is_click_inventory integer DEFAULT 0,
    is_click_opportunities integer DEFAULT 0,
    is_click_target_rate integer DEFAULT 0,
    is_click_bids integer DEFAULT 0,
    is_click_bid_rate integer DEFAULT 0,
    is_click_impressions integer DEFAULT 0,
    is_click_total_clicks integer DEFAULT 0,
    is_click_success_rate integer DEFAULT 0,
    is_click_avg_bid integer DEFAULT 0,
    is_click_avg_cpc integer DEFAULT 0,
    is_click_total_cost integer DEFAULT 0,
    is_click_profit integer DEFAULT 0,
    is_click_cm integer DEFAULT 0,
    is_click_product integer DEFAULT 0,
    is_click_type integer DEFAULT 0,
    is_click_daily_limit integer DEFAULT 0,
    is_click_monthly_limit integer DEFAULT 0,
    is_generic_units integer DEFAULT 0,
    is_generic_avg_bid integer DEFAULT 0,
    is_generic_cpx integer DEFAULT 0,
    is_generic_spend integer DEFAULT 0,
    is_campaign_pace integer DEFAULT 0,
    is_campaign_notes integer DEFAULT 0,
    product_type integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_click_total_leads integer DEFAULT 0,
    is_click_total_calls integer DEFAULT 0
);


ALTER TABLE public.campaigns_customize_columns_orders OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 93818)
-- Name: campaigns_customize_columns_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaigns_customize_columns_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaigns_customize_columns_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7709 (class 0 OID 0)
-- Dependencies: 366
-- Name: campaigns_customize_columns_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaigns_customize_columns_orders_id_seq OWNED BY public.campaigns_customize_columns_orders.id;


--
-- TOC entry 367 (class 1259 OID 93820)
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campaigns_id_seq OWNER TO postgres;

--
-- TOC entry 7710 (class 0 OID 0)
-- Dependencies: 367
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaigns_id_seq OWNED BY public.campaigns.id;


--
-- TOC entry 368 (class 1259 OID 93822)
-- Name: ccpa_opted_out_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ccpa_opted_out_users (
    id bigint NOT NULL,
    first_name character varying,
    last_name character varying,
    address character varying,
    city character varying,
    state character varying,
    zip_code bigint,
    email character varying,
    phone_num character varying,
    agent_first_name character varying,
    agent_last_name character varying,
    agent_email character varying,
    agent_phone character varying,
    preferred_method_for_questions character varying,
    receive_information_via character varying,
    access_personal_information boolean,
    type_of_info_like_to_receive character varying,
    personal_information_souces_type boolean,
    business_purpose_type boolean,
    third_parties_information boolean,
    business_purposes_for_disclose boolean,
    delete_personal_info boolean,
    opt_out_of_sale boolean,
    authorized_agent boolean,
    ip character varying,
    user_agent text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ccpa_opted_out_users OWNER TO postgres;

--
-- TOC entry 369 (class 1259 OID 93828)
-- Name: ccpa_opted_out_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ccpa_opted_out_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ccpa_opted_out_users_id_seq OWNER TO postgres;

--
-- TOC entry 7711 (class 0 OID 0)
-- Dependencies: 369
-- Name: ccpa_opted_out_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ccpa_opted_out_users_id_seq OWNED BY public.ccpa_opted_out_users.id;


--
-- TOC entry 370 (class 1259 OID 93830)
-- Name: click_ad_group_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_ad_group_settings (
    id bigint NOT NULL,
    dest_url character varying,
    fallback_url character varying,
    ad_group_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    click_integration_id bigint,
    has_click_integration boolean DEFAULT false
);


ALTER TABLE public.click_ad_group_settings OWNER TO postgres;

--
-- TOC entry 371 (class 1259 OID 93837)
-- Name: click_ad_group_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_ad_group_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_ad_group_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7712 (class 0 OID 0)
-- Dependencies: 371
-- Name: click_ad_group_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_ad_group_settings_id_seq OWNED BY public.click_ad_group_settings.id;


--
-- TOC entry 372 (class 1259 OID 93839)
-- Name: click_campaign_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_campaign_settings (
    id bigint NOT NULL,
    dest_url text,
    fallback_url text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tracking_at_ad_group_level boolean DEFAULT false,
    campaign_id bigint,
    discarded_at timestamp(6) without time zone,
    click_integration_id bigint,
    has_click_integration boolean DEFAULT false,
    pub_aid character varying,
    pub_cid character varying,
    append_tracking text,
    throttle integer,
    postback_url text,
    bpfm_status boolean DEFAULT true,
    target_cpc numeric(5,2),
    floor_cpc numeric(5,2)
);


ALTER TABLE public.click_campaign_settings OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 93848)
-- Name: click_campaign_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_campaign_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_campaign_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7713 (class 0 OID 0)
-- Dependencies: 373
-- Name: click_campaign_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_campaign_settings_id_seq OWNED BY public.click_campaign_settings.id;


--
-- TOC entry 374 (class 1259 OID 93850)
-- Name: click_conversion_errors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_conversion_errors (
    id bigint NOT NULL,
    click_conversion_pixel_id bigint,
    click_id character varying,
    ip_address character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    product_type_id bigint NOT NULL,
    caller_id character varying,
    lead_id character varying
);


ALTER TABLE public.click_conversion_errors OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 93856)
-- Name: click_conversion_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_conversion_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_conversion_errors_id_seq OWNER TO postgres;

--
-- TOC entry 7714 (class 0 OID 0)
-- Dependencies: 375
-- Name: click_conversion_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_conversion_errors_id_seq OWNED BY public.click_conversion_errors.id;


--
-- TOC entry 376 (class 1259 OID 93858)
-- Name: click_conversion_log_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_conversion_log_details (
    id bigint NOT NULL,
    failed boolean,
    created boolean,
    updated boolean,
    conversion_message character varying,
    click_conversion_log_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    click_conversion_pixel_id integer,
    converted boolean,
    error text,
    revenue numeric(10,2),
    success_criteria_type character varying,
    success_criteria_value character varying,
    mapped_value character varying,
    product_type_identifiers character varying
);


ALTER TABLE public.click_conversion_log_details OWNER TO postgres;

--
-- TOC entry 377 (class 1259 OID 93864)
-- Name: click_conversion_log_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_conversion_log_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_conversion_log_details_id_seq OWNER TO postgres;

--
-- TOC entry 7715 (class 0 OID 0)
-- Dependencies: 377
-- Name: click_conversion_log_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_conversion_log_details_id_seq OWNED BY public.click_conversion_log_details.id;


--
-- TOC entry 378 (class 1259 OID 93866)
-- Name: click_conversion_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_conversion_logs (
    id bigint NOT NULL,
    file_s3_url character varying,
    status character varying,
    account_id bigint NOT NULL,
    brand_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL,
    url character varying,
    file_name character varying,
    total_records integer DEFAULT 0,
    processed_records integer DEFAULT 0,
    discarded_at timestamp(6) without time zone,
    event integer,
    product_type_id bigint NOT NULL,
    token character varying,
    total_revenue numeric(20,2),
    log text
);


ALTER TABLE public.click_conversion_logs OWNER TO postgres;

--
-- TOC entry 379 (class 1259 OID 93874)
-- Name: click_conversion_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_conversion_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_conversion_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7716 (class 0 OID 0)
-- Dependencies: 379
-- Name: click_conversion_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_conversion_logs_id_seq OWNED BY public.click_conversion_logs.id;


--
-- TOC entry 380 (class 1259 OID 93876)
-- Name: click_conversion_pixels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_conversion_pixels (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    brand_id bigint NOT NULL,
    name character varying,
    description character varying,
    status boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.click_conversion_pixels OWNER TO postgres;

--
-- TOC entry 381 (class 1259 OID 93882)
-- Name: click_conversion_pixels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_conversion_pixels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_conversion_pixels_id_seq OWNER TO postgres;

--
-- TOC entry 7717 (class 0 OID 0)
-- Dependencies: 381
-- Name: click_conversion_pixels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_conversion_pixels_id_seq OWNED BY public.click_conversion_pixels.id;


--
-- TOC entry 382 (class 1259 OID 93884)
-- Name: click_conversions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_conversions (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    brand_id bigint NOT NULL,
    campaign_id bigint,
    click_listing_id bigint,
    click_conversion_pixel_id bigint NOT NULL,
    ip_address character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    click_id character varying,
    revenue numeric(10,2),
    channel character varying,
    product_type_id bigint NOT NULL,
    caller_id character varying,
    lead_id character varying,
    lead_listing_id bigint,
    call_listing_id bigint,
    discarded_at timestamp(6) without time zone,
    rev_type character varying,
    ad_group_id integer,
    listing_created_at timestamp(6) without time zone,
    rev_channel character varying
);


ALTER TABLE public.click_conversions OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 93890)
-- Name: click_conversions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_conversions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_conversions_id_seq OWNER TO postgres;

--
-- TOC entry 7718 (class 0 OID 0)
-- Dependencies: 383
-- Name: click_conversions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_conversions_id_seq OWNED BY public.click_conversions.id;


--
-- TOC entry 384 (class 1259 OID 93892)
-- Name: click_integration_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_integration_logs (
    id bigint NOT NULL,
    click_integration_id integer,
    partner_name character varying,
    request text,
    response text,
    success boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.click_integration_logs OWNER TO postgres;

--
-- TOC entry 385 (class 1259 OID 93898)
-- Name: click_integration_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_integration_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_integration_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7719 (class 0 OID 0)
-- Dependencies: 385
-- Name: click_integration_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_integration_logs_id_seq OWNED BY public.click_integration_logs.id;


--
-- TOC entry 386 (class 1259 OID 93900)
-- Name: click_integration_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_integration_types (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.click_integration_types OWNER TO postgres;

--
-- TOC entry 387 (class 1259 OID 93906)
-- Name: click_integration_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_integration_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_integration_types_id_seq OWNER TO postgres;

--
-- TOC entry 7720 (class 0 OID 0)
-- Dependencies: 387
-- Name: click_integration_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_integration_types_id_seq OWNED BY public.click_integration_types.id;


--
-- TOC entry 388 (class 1259 OID 93908)
-- Name: click_integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_integrations (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    name character varying,
    dest_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    click_integration_type_id bigint NOT NULL
);


ALTER TABLE public.click_integrations OWNER TO postgres;

--
-- TOC entry 389 (class 1259 OID 93914)
-- Name: click_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_integrations_id_seq OWNER TO postgres;

--
-- TOC entry 7721 (class 0 OID 0)
-- Dependencies: 389
-- Name: click_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_integrations_id_seq OWNED BY public.click_integrations.id;


--
-- TOC entry 390 (class 1259 OID 93916)
-- Name: click_listings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_listings (
    id bigint NOT NULL,
    click_ping_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    ad_group_id bigint NOT NULL,
    ad_id bigint NOT NULL,
    title character varying,
    description text,
    click_url text,
    tracking_url text,
    logo_url text,
    site_host character varying,
    company_name character varying,
    display_name character varying,
    payout numeric(20,2),
    est_payout numeric(20,2),
    viewed smallint DEFAULT 0,
    clicked smallint DEFAULT 0,
    email_click integer,
    premium character varying,
    term character varying,
    "position" numeric(5,2),
    response_partner_id bigint,
    de_duped smallint DEFAULT 0,
    excluded smallint DEFAULT 0,
    carrier_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    click_id character varying(32) NOT NULL,
    brand_id bigint,
    account_id bigint,
    fallback_url character varying,
    device_type_mobile boolean,
    pst_date date,
    state character varying,
    source_type_id integer,
    lead_type_id integer,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    rd_dup boolean,
    ping_post boolean,
    pp_ping_id character varying,
    pp_bid_id character varying,
    upstream_bid numeric(7,2),
    product_type_id integer,
    network_id integer,
    current_bid numeric(8,2),
    prefill_failed boolean
);


ALTER TABLE public.click_listings OWNER TO postgres;

--
-- TOC entry 391 (class 1259 OID 93926)
-- Name: click_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_listings_id_seq OWNER TO postgres;

--
-- TOC entry 7722 (class 0 OID 0)
-- Dependencies: 391
-- Name: click_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_listings_id_seq OWNED BY public.click_listings.id;


--
-- TOC entry 392 (class 1259 OID 93928)
-- Name: click_opportunities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_opportunities (
    id bigint NOT NULL,
    click_ping_id integer,
    campaign_id integer,
    ad_group_id integer,
    ad_id integer,
    brand_id integer,
    account_id integer,
    payout numeric(10,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lead_type_id integer,
    source_type_id integer,
    active_source_setting boolean,
    product_type_id integer
);


ALTER TABLE public.click_opportunities OWNER TO postgres;

--
-- TOC entry 393 (class 1259 OID 93931)
-- Name: click_opportunities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_opportunities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_opportunities_id_seq OWNER TO postgres;

--
-- TOC entry 7723 (class 0 OID 0)
-- Dependencies: 393
-- Name: click_opportunities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_opportunities_id_seq OWNED BY public.click_opportunities.id;


--
-- TOC entry 394 (class 1259 OID 93933)
-- Name: click_panels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_panels (
    id bigint NOT NULL,
    click_listing_id integer,
    click_ping_id integer,
    advertiser character varying,
    "position" integer,
    payout numeric(8,2),
    clicked boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.click_panels OWNER TO postgres;

--
-- TOC entry 395 (class 1259 OID 93939)
-- Name: click_panels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_panels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_panels_id_seq OWNER TO postgres;

--
-- TOC entry 7724 (class 0 OID 0)
-- Dependencies: 395
-- Name: click_panels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_panels_id_seq OWNED BY public.click_panels.id;


--
-- TOC entry 396 (class 1259 OID 93941)
-- Name: click_ping_debug_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_ping_debug_logs (
    id bigint NOT NULL,
    click_ping_id integer,
    log text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    response_time_ms integer,
    num_listings integer,
    token character varying
);


ALTER TABLE public.click_ping_debug_logs OWNER TO postgres;

--
-- TOC entry 397 (class 1259 OID 93947)
-- Name: click_ping_debug_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_ping_debug_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_ping_debug_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7725 (class 0 OID 0)
-- Dependencies: 397
-- Name: click_ping_debug_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_ping_debug_logs_id_seq OWNED BY public.click_ping_debug_logs.id;


--
-- TOC entry 398 (class 1259 OID 93949)
-- Name: click_ping_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_ping_details (
    id bigint NOT NULL,
    click_ping_id bigint NOT NULL,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age integer,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    phone character varying,
    email character varying,
    city character varying,
    county character varying,
    tobacco character varying,
    major_health_conditions character varying,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    referrer character varying,
    sr22 character varying,
    slice_num character varying,
    bundle_home character varying,
    insco character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    ip_address character varying
);


ALTER TABLE public.click_ping_details OWNER TO postgres;

--
-- TOC entry 399 (class 1259 OID 93955)
-- Name: click_ping_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_ping_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_ping_details_id_seq OWNER TO postgres;

--
-- TOC entry 7726 (class 0 OID 0)
-- Dependencies: 399
-- Name: click_ping_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_ping_details_id_seq OWNED BY public.click_ping_details.id;


--
-- TOC entry 400 (class 1259 OID 93957)
-- Name: click_ping_matches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_ping_matches (
    id bigint NOT NULL,
    click_ping_id integer,
    account_id integer,
    campaign_id integer,
    ad_group_id integer,
    brand_id integer,
    ad_group_active boolean,
    payout numeric(10,2),
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    product_type_id integer
);


ALTER TABLE public.click_ping_matches OWNER TO postgres;

--
-- TOC entry 401 (class 1259 OID 93960)
-- Name: click_ping_matches_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_ping_matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_ping_matches_id_seq OWNER TO postgres;

--
-- TOC entry 7727 (class 0 OID 0)
-- Dependencies: 401
-- Name: click_ping_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_ping_matches_id_seq OWNED BY public.click_ping_matches.id;


--
-- TOC entry 402 (class 1259 OID 93962)
-- Name: click_ping_vals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_ping_vals (
    id bigint NOT NULL,
    click_ping_id integer,
    incoming_data text,
    processed_data text,
    defaults text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.click_ping_vals OWNER TO postgres;

--
-- TOC entry 403 (class 1259 OID 93968)
-- Name: click_ping_vals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_ping_vals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_ping_vals_id_seq OWNER TO postgres;

--
-- TOC entry 7728 (class 0 OID 0)
-- Dependencies: 403
-- Name: click_ping_vals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_ping_vals_id_seq OWNED BY public.click_ping_vals.id;


--
-- TOC entry 404 (class 1259 OID 93970)
-- Name: click_pings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_pings (
    id bigint NOT NULL,
    partner_id character varying,
    lead_type_id bigint,
    session_id character varying,
    zip character varying,
    state character varying,
    device_type character varying,
    source_type_id bigint,
    form_type_id bigint,
    aid character varying,
    cid character varying,
    sid character varying,
    ks character varying,
    num_clicks bigint,
    xml text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    total_opportunities integer,
    filtered_listings integer,
    full_data boolean,
    prefill_perc numeric(5,2),
    missing_fields text,
    pii boolean,
    ttr_ms character varying
);


ALTER TABLE public.click_pings OWNER TO postgres;

--
-- TOC entry 405 (class 1259 OID 93976)
-- Name: click_pings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_pings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_pings_id_seq OWNER TO postgres;

--
-- TOC entry 7729 (class 0 OID 0)
-- Dependencies: 405
-- Name: click_pings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_pings_id_seq OWNED BY public.click_pings.id;


--
-- TOC entry 406 (class 1259 OID 93978)
-- Name: click_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_posts (
    id bigint NOT NULL,
    partner_id character varying,
    click_ping_id integer,
    click_listing_id integer,
    campaign_id integer,
    data text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.click_posts OWNER TO postgres;

--
-- TOC entry 407 (class 1259 OID 93984)
-- Name: click_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_posts_id_seq OWNER TO postgres;

--
-- TOC entry 7730 (class 0 OID 0)
-- Dependencies: 407
-- Name: click_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_posts_id_seq OWNED BY public.click_posts.id;


--
-- TOC entry 408 (class 1259 OID 93986)
-- Name: click_receipts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_receipts (
    id bigint NOT NULL,
    click_listing_id bigint NOT NULL,
    ip_address character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.click_receipts OWNER TO postgres;

--
-- TOC entry 409 (class 1259 OID 93992)
-- Name: click_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_receipts_id_seq OWNER TO postgres;

--
-- TOC entry 7731 (class 0 OID 0)
-- Dependencies: 409
-- Name: click_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_receipts_id_seq OWNED BY public.click_receipts.id;


--
-- TOC entry 410 (class 1259 OID 93994)
-- Name: click_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.click_results (
    id bigint NOT NULL,
    click_ping_id integer,
    account_id integer,
    campaign_id integer,
    brand_id integer,
    ad_group_id integer,
    ad_id integer,
    title character varying,
    description text,
    click_url text,
    tracking_url text,
    logo_url text,
    site_host character varying,
    company_name character varying,
    display_name character varying,
    payout numeric(10,2),
    est_payout numeric(10,2),
    viewed boolean,
    clicked boolean,
    email_click boolean,
    premium character varying,
    term character varying,
    "position" numeric(5,2),
    response_partner_id integer,
    de_duped boolean,
    excluded boolean,
    carrier_id integer,
    click_id character varying,
    fallback_url text,
    device_type character varying,
    zip character varying,
    state character varying,
    source_type_id integer,
    active_source boolean,
    lead_type_id integer,
    match boolean,
    opportunity boolean,
    listing boolean,
    aid character varying,
    cid character varying,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    mobile boolean,
    clicked_at timestamp(6) without time zone,
    pub_aid character varying,
    pub_cid character varying,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age integer,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    phone character varying,
    email character varying,
    city character varying,
    county character varying,
    tobacco character varying,
    major_health_conditions character varying,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    ip_address character varying,
    col1 character varying,
    col2 character varying,
    col3 character varying,
    col4 character varying,
    col5 character varying,
    disqualification_reason character varying,
    partner_id character varying,
    full_data boolean,
    prefill_perc numeric(5,2),
    missing_fields text,
    pii boolean,
    backfilled boolean,
    upstream_bid numeric(7,2),
    product_type_id integer,
    network_id integer,
    click_listing_id integer
);


ALTER TABLE public.click_results OWNER TO postgres;

--
-- TOC entry 411 (class 1259 OID 94000)
-- Name: click_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.click_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.click_results_id_seq OWNER TO postgres;

--
-- TOC entry 7732 (class 0 OID 0)
-- Dependencies: 411
-- Name: click_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.click_results_id_seq OWNED BY public.click_results.id;


--
-- TOC entry 412 (class 1259 OID 94002)
-- Name: clicks_dashboard_customize_column_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clicks_dashboard_customize_column_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    state_queries integer DEFAULT 0,
    state_searches integer DEFAULT 0,
    state_cost integer DEFAULT 0,
    state_impressions integer DEFAULT 0,
    state_clicks integer DEFAULT 0,
    state_ctr integer DEFAULT 0,
    state_avg_cpc integer DEFAULT 0,
    state_avg_bid integer DEFAULT 0,
    state_avg_pos integer DEFAULT 0,
    source_queries integer DEFAULT 0,
    source_searches integer DEFAULT 0,
    source_cost integer DEFAULT 0,
    source_impressions integer DEFAULT 0,
    source_clicks integer DEFAULT 0,
    source_ctr integer DEFAULT 0,
    source_avg_cpc integer DEFAULT 0,
    source_avg_bid integer DEFAULT 0,
    source_avg_pos integer DEFAULT 0,
    creative_queries integer DEFAULT 0,
    creative_searches integer DEFAULT 0,
    creative_cost integer DEFAULT 0,
    creative_impressions integer DEFAULT 0,
    creative_clicks integer DEFAULT 0,
    creative_ctr integer DEFAULT 0,
    creative_avg_cpc integer DEFAULT 0,
    creative_avg_bid integer DEFAULT 0,
    creative_avg_pos integer DEFAULT 0,
    insurance_type_queries integer DEFAULT 0,
    insurance_type_searches integer DEFAULT 0,
    insurance_type_cost integer DEFAULT 0,
    insurance_type_impressions integer DEFAULT 0,
    insurance_type_clicks integer DEFAULT 0,
    insurance_type_ctr integer DEFAULT 0,
    insurance_type_avg_cpc integer DEFAULT 0,
    insurance_type_avg_bid integer DEFAULT 0,
    insurance_type_avg_pos integer DEFAULT 0,
    state_total_leads integer DEFAULT 0,
    state_total_calls integer DEFAULT 0,
    source_total_leads integer DEFAULT 0,
    source_total_calls integer DEFAULT 0,
    creative_total_leads integer DEFAULT 0,
    creative_total_calls integer DEFAULT 0,
    insurance_type_total_leads integer DEFAULT 0,
    insurance_type_total_calls integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.clicks_dashboard_customize_column_orders OWNER TO postgres;

--
-- TOC entry 413 (class 1259 OID 94049)
-- Name: clicks_dashboard_customize_column_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clicks_dashboard_customize_column_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clicks_dashboard_customize_column_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7733 (class 0 OID 0)
-- Dependencies: 413
-- Name: clicks_dashboard_customize_column_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clicks_dashboard_customize_column_orders_id_seq OWNED BY public.clicks_dashboard_customize_column_orders.id;


--
-- TOC entry 414 (class 1259 OID 94051)
-- Name: close_com_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.close_com_items (
    id bigint NOT NULL,
    close_com_id character varying NOT NULL,
    label character varying NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    item_type character varying,
    cotype_id character varying,
    db_field_key character varying
);


ALTER TABLE public.close_com_items OWNER TO postgres;

--
-- TOC entry 415 (class 1259 OID 94057)
-- Name: close_com_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.close_com_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.close_com_items_id_seq OWNER TO postgres;

--
-- TOC entry 7734 (class 0 OID 0)
-- Dependencies: 415
-- Name: close_com_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.close_com_items_id_seq OWNED BY public.close_com_items.id;


--
-- TOC entry 416 (class 1259 OID 94059)
-- Name: conversion_log_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversion_log_transactions (
    id bigint NOT NULL,
    click_conversion_log_id bigint NOT NULL,
    click_conversion_id bigint NOT NULL,
    event character varying,
    previous_object json,
    current_object json,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.conversion_log_transactions OWNER TO postgres;

--
-- TOC entry 417 (class 1259 OID 94065)
-- Name: conversion_log_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conversion_log_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.conversion_log_transactions_id_seq OWNER TO postgres;

--
-- TOC entry 7735 (class 0 OID 0)
-- Dependencies: 417
-- Name: conversion_log_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conversion_log_transactions_id_seq OWNED BY public.conversion_log_transactions.id;


--
-- TOC entry 418 (class 1259 OID 94067)
-- Name: conversions_logs_pixel_cols; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversions_logs_pixel_cols (
    id bigint NOT NULL,
    click_conversion_pixel_id bigint NOT NULL,
    disp_new boolean DEFAULT true,
    disp_updated boolean DEFAULT true,
    disp_invalid boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.conversions_logs_pixel_cols OWNER TO postgres;

--
-- TOC entry 419 (class 1259 OID 94073)
-- Name: conversions_logs_pixel_cols_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conversions_logs_pixel_cols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.conversions_logs_pixel_cols_id_seq OWNER TO postgres;

--
-- TOC entry 7736 (class 0 OID 0)
-- Dependencies: 419
-- Name: conversions_logs_pixel_cols_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conversions_logs_pixel_cols_id_seq OWNED BY public.conversions_logs_pixel_cols.id;


--
-- TOC entry 420 (class 1259 OID 94075)
-- Name: custom_intermediate_integration_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_intermediate_integration_configs (
    id bigint NOT NULL,
    config_type character varying,
    config_id text,
    config text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.custom_intermediate_integration_configs OWNER TO postgres;

--
-- TOC entry 421 (class 1259 OID 94081)
-- Name: custom_intermediate_integration_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.custom_intermediate_integration_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.custom_intermediate_integration_configs_id_seq OWNER TO postgres;

--
-- TOC entry 7737 (class 0 OID 0)
-- Dependencies: 421
-- Name: custom_intermediate_integration_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.custom_intermediate_integration_configs_id_seq OWNED BY public.custom_intermediate_integration_configs.id;


--
-- TOC entry 422 (class 1259 OID 94083)
-- Name: customize_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customize_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    campaigns text,
    adgroup text,
    profile text,
    source_setting text,
    analytics text,
    leads_calls_source_setting text,
    conversion_logs text,
    admin_clients text,
    user_activity text,
    clicks_dashboard text,
    calls_dashboard text,
    leads_dashboard text,
    quote_funnel_dashboard text,
    syndi_clicks_dashboard text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.customize_orders OWNER TO postgres;

--
-- TOC entry 423 (class 1259 OID 94089)
-- Name: customize_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customize_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customize_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7738 (class 0 OID 0)
-- Dependencies: 423
-- Name: customize_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customize_orders_id_seq OWNED BY public.customize_orders.id;


--
-- TOC entry 424 (class 1259 OID 94091)
-- Name: days; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.days (
    id bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.days OWNER TO postgres;

--
-- TOC entry 425 (class 1259 OID 94097)
-- Name: days_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.days_id_seq OWNER TO postgres;

--
-- TOC entry 7739 (class 0 OID 0)
-- Dependencies: 425
-- Name: days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.days_id_seq OWNED BY public.days.id;


--
-- TOC entry 426 (class 1259 OID 94099)
-- Name: dms_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dms_logs (
    id bigint NOT NULL,
    log_stream character varying NOT NULL,
    message text,
    message_type character varying,
    message_id character varying,
    "timestamp" timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jira_key character varying
);


ALTER TABLE public.dms_logs OWNER TO postgres;

--
-- TOC entry 427 (class 1259 OID 94106)
-- Name: dms_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dms_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dms_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7740 (class 0 OID 0)
-- Dependencies: 427
-- Name: dms_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dms_logs_id_seq OWNED BY public.dms_logs.id;


--
-- TOC entry 428 (class 1259 OID 94108)
-- Name: email_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_events (
    id bigint NOT NULL,
    email character varying,
    category character varying,
    event character varying,
    user_id bigint,
    sg_event_id character varying,
    sg_message_id character varying,
    "timestamp" bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    template_id character varying,
    account_id bigint
);


ALTER TABLE public.email_events OWNER TO postgres;

--
-- TOC entry 429 (class 1259 OID 94114)
-- Name: email_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_events_id_seq OWNER TO postgres;

--
-- TOC entry 7741 (class 0 OID 0)
-- Dependencies: 429
-- Name: email_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_events_id_seq OWNED BY public.email_events.id;


--
-- TOC entry 430 (class 1259 OID 94116)
-- Name: email_export_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_export_logs (
    id bigint NOT NULL,
    user_id bigint,
    account_id bigint NOT NULL,
    admin_user_id bigint,
    page_name character varying,
    file character varying,
    token character varying,
    export_params text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.email_export_logs OWNER TO postgres;

--
-- TOC entry 431 (class 1259 OID 94122)
-- Name: email_export_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_export_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_export_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7742 (class 0 OID 0)
-- Dependencies: 431
-- Name: email_export_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_export_logs_id_seq OWNED BY public.email_export_logs.id;


--
-- TOC entry 432 (class 1259 OID 94124)
-- Name: email_template_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_template_logs (
    id bigint NOT NULL,
    template_body text,
    template_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.email_template_logs OWNER TO postgres;

--
-- TOC entry 433 (class 1259 OID 94130)
-- Name: email_template_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_template_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_template_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7743 (class 0 OID 0)
-- Dependencies: 433
-- Name: email_template_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_template_logs_id_seq OWNED BY public.email_template_logs.id;


--
-- TOC entry 434 (class 1259 OID 94132)
-- Name: farmers_skus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmers_skus (
    id bigint NOT NULL,
    product_type_id integer NOT NULL,
    lead_type_id integer NOT NULL,
    exclusive boolean,
    sku character varying NOT NULL,
    folio_eligible boolean DEFAULT false NOT NULL,
    cost_share_eligible boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.farmers_skus OWNER TO postgres;

--
-- TOC entry 435 (class 1259 OID 94140)
-- Name: farmers_skus_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.farmers_skus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.farmers_skus_id_seq OWNER TO postgres;

--
-- TOC entry 7744 (class 0 OID 0)
-- Dependencies: 435
-- Name: farmers_skus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.farmers_skus_id_seq OWNED BY public.farmers_skus.id;


--
-- TOC entry 436 (class 1259 OID 94142)
-- Name: features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.features (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    create_flag boolean DEFAULT false NOT NULL,
    read_flag boolean DEFAULT false NOT NULL,
    update_flag boolean DEFAULT false NOT NULL,
    delete_flag boolean DEFAULT false NOT NULL
);


ALTER TABLE public.features OWNER TO postgres;

--
-- TOC entry 437 (class 1259 OID 94152)
-- Name: features_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.features_id_seq OWNER TO postgres;

--
-- TOC entry 7745 (class 0 OID 0)
-- Dependencies: 437
-- Name: features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.features_id_seq OWNED BY public.features.id;


--
-- TOC entry 438 (class 1259 OID 94154)
-- Name: filter_package_filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.filter_package_filters (
    id bigint NOT NULL,
    filter_package_id bigint NOT NULL,
    sf_filter_id bigint NOT NULL,
    filter_value character varying,
    include boolean,
    filter_value_min character varying,
    filter_value_max character varying,
    price numeric(20,2),
    discarded_at timestamp(6) without time zone,
    accept_unknown boolean DEFAULT true,
    filter_value_array text[] DEFAULT '{}'::text[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying,
    filter_type character varying
);


ALTER TABLE public.filter_package_filters OWNER TO postgres;

--
-- TOC entry 439 (class 1259 OID 94162)
-- Name: filter_package_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.filter_package_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.filter_package_filters_id_seq OWNER TO postgres;

--
-- TOC entry 7746 (class 0 OID 0)
-- Dependencies: 439
-- Name: filter_package_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.filter_package_filters_id_seq OWNED BY public.filter_package_filters.id;


--
-- TOC entry 440 (class 1259 OID 94164)
-- Name: filter_packages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.filter_packages (
    id bigint NOT NULL,
    product_type_id bigint,
    lead_type_id bigint,
    name character varying,
    price numeric(20,2),
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    exclusive boolean DEFAULT false NOT NULL,
    carrier_ids text[] DEFAULT '{}'::text[]
);


ALTER TABLE public.filter_packages OWNER TO postgres;

--
-- TOC entry 441 (class 1259 OID 94172)
-- Name: filter_packages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.filter_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.filter_packages_id_seq OWNER TO postgres;

--
-- TOC entry 7747 (class 0 OID 0)
-- Dependencies: 441
-- Name: filter_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.filter_packages_id_seq OWNED BY public.filter_packages.id;


--
-- TOC entry 442 (class 1259 OID 94174)
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.flipper_features OWNER TO postgres;

--
-- TOC entry 443 (class 1259 OID 94180)
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flipper_features_id_seq OWNER TO postgres;

--
-- TOC entry 7748 (class 0 OID 0)
-- Dependencies: 443
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- TOC entry 444 (class 1259 OID 94182)
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.flipper_gates OWNER TO postgres;

--
-- TOC entry 445 (class 1259 OID 94188)
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flipper_gates_id_seq OWNER TO postgres;

--
-- TOC entry 7749 (class 0 OID 0)
-- Dependencies: 445
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- TOC entry 446 (class 1259 OID 94190)
-- Name: history_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.history_versions (
    id bigint NOT NULL,
    item_type character varying NOT NULL,
    item_id bigint NOT NULL,
    item_name character varying,
    event character varying NOT NULL,
    changed_attribute character varying NOT NULL,
    value_type character varying,
    previous_value character varying,
    new_value character varying,
    parent_type character varying,
    parent_id bigint,
    parent_name character varying,
    user_id bigint,
    campaign_id bigint,
    account_id bigint,
    version_id bigint,
    created_at timestamp(6) without time zone,
    brand_id bigint,
    extra_data jsonb,
    admin_user_id bigint
);


ALTER TABLE public.history_versions OWNER TO postgres;

--
-- TOC entry 447 (class 1259 OID 94196)
-- Name: history_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.history_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.history_versions_id_seq OWNER TO postgres;

--
-- TOC entry 7750 (class 0 OID 0)
-- Dependencies: 447
-- Name: history_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.history_versions_id_seq OWNED BY public.history_versions.id;


--
-- TOC entry 448 (class 1259 OID 94198)
-- Name: insurance_carriers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insurance_carriers (
    id bigint NOT NULL,
    name character varying,
    active integer,
    recording_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.insurance_carriers OWNER TO postgres;

--
-- TOC entry 449 (class 1259 OID 94204)
-- Name: insurance_carriers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.insurance_carriers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.insurance_carriers_id_seq OWNER TO postgres;

--
-- TOC entry 7751 (class 0 OID 0)
-- Dependencies: 449
-- Name: insurance_carriers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.insurance_carriers_id_seq OWNED BY public.insurance_carriers.id;


--
-- TOC entry 450 (class 1259 OID 94206)
-- Name: intermediate_lead_integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.intermediate_lead_integrations (
    id bigint NOT NULL,
    lead_integration_id bigint,
    intermediate_integration_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.intermediate_lead_integrations OWNER TO postgres;

--
-- TOC entry 451 (class 1259 OID 94209)
-- Name: intermediate_lead_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.intermediate_lead_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.intermediate_lead_integrations_id_seq OWNER TO postgres;

--
-- TOC entry 7752 (class 0 OID 0)
-- Dependencies: 451
-- Name: intermediate_lead_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.intermediate_lead_integrations_id_seq OWNED BY public.intermediate_lead_integrations.id;


--
-- TOC entry 452 (class 1259 OID 94211)
-- Name: internal_api_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.internal_api_tokens (
    id bigint NOT NULL,
    api_token character varying,
    api_secret character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying
);


ALTER TABLE public.internal_api_tokens OWNER TO postgres;

--
-- TOC entry 453 (class 1259 OID 94217)
-- Name: internal_api_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.internal_api_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.internal_api_tokens_id_seq OWNER TO postgres;

--
-- TOC entry 7753 (class 0 OID 0)
-- Dependencies: 453
-- Name: internal_api_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.internal_api_tokens_id_seq OWNED BY public.internal_api_tokens.id;


--
-- TOC entry 454 (class 1259 OID 94219)
-- Name: invoice_raw_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_raw_stats (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    campaign_wise_data jsonb,
    product_type_wise_data jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.invoice_raw_stats OWNER TO postgres;

--
-- TOC entry 455 (class 1259 OID 94225)
-- Name: invoice_raw_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_raw_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invoice_raw_stats_id_seq OWNER TO postgres;

--
-- TOC entry 7754 (class 0 OID 0)
-- Dependencies: 455
-- Name: invoice_raw_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_raw_stats_id_seq OWNED BY public.invoice_raw_stats.id;


--
-- TOC entry 456 (class 1259 OID 94227)
-- Name: invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoices (
    id bigint NOT NULL,
    month integer,
    year integer,
    account_id bigint NOT NULL,
    brand_id bigint NOT NULL,
    payment_term_id bigint NOT NULL,
    ref_id character varying,
    due_date date,
    amount numeric,
    paid_amount numeric,
    outstanding_balance numeric,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    from_date date,
    to_date date,
    date_paid date,
    generated boolean DEFAULT false,
    carry_over numeric,
    memo character varying,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.invoices OWNER TO postgres;

--
-- TOC entry 457 (class 1259 OID 94234)
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invoices_id_seq OWNER TO postgres;

--
-- TOC entry 7755 (class 0 OID 0)
-- Dependencies: 457
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoices_id_seq OWNED BY public.invoices.id;


--
-- TOC entry 458 (class 1259 OID 94236)
-- Name: jira_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jira_users (
    id bigint NOT NULL,
    email character varying,
    api_token character varying,
    url character varying,
    project_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.jira_users OWNER TO postgres;

--
-- TOC entry 459 (class 1259 OID 94242)
-- Name: jira_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jira_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jira_users_id_seq OWNER TO postgres;

--
-- TOC entry 7756 (class 0 OID 0)
-- Dependencies: 459
-- Name: jira_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jira_users_id_seq OWNED BY public.jira_users.id;


--
-- TOC entry 460 (class 1259 OID 94244)
-- Name: jwt_denylist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jwt_denylist (
    id bigint NOT NULL,
    jti character varying NOT NULL,
    exp timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.jwt_denylist OWNER TO postgres;

--
-- TOC entry 461 (class 1259 OID 94250)
-- Name: jwt_denylist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jwt_denylist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jwt_denylist_id_seq OWNER TO postgres;

--
-- TOC entry 7757 (class 0 OID 0)
-- Dependencies: 461
-- Name: jwt_denylist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jwt_denylist_id_seq OWNED BY public.jwt_denylist.id;


--
-- TOC entry 462 (class 1259 OID 94252)
-- Name: lead_applicants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_applicants (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    first_name character varying,
    last_name character varying,
    dob date,
    gender character varying,
    marital_status character varying,
    relation character varying,
    license_state character varying,
    license_status character varying,
    licensed_age integer,
    education character varying,
    occupation character varying,
    yrs_in_occupation integer,
    sr_22 boolean DEFAULT false,
    suspension boolean DEFAULT false,
    dui boolean DEFAULT false,
    credit character varying,
    dl_num character varying,
    height_ft integer,
    height_in integer,
    weight integer,
    military_service boolean,
    medications boolean,
    has_pre_existing_conditions boolean,
    tobacco boolean,
    expectant boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_applicants OWNER TO postgres;

--
-- TOC entry 463 (class 1259 OID 94261)
-- Name: lead_applicants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_applicants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_applicants_id_seq OWNER TO postgres;

--
-- TOC entry 7758 (class 0 OID 0)
-- Dependencies: 463
-- Name: lead_applicants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_applicants_id_seq OWNED BY public.lead_applicants.id;


--
-- TOC entry 464 (class 1259 OID 94263)
-- Name: lead_business_entities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_business_entities (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    business_name character varying,
    business_desc text,
    address character varying,
    city character varying,
    county character varying,
    state character varying,
    zip character varying,
    legal_entity character varying,
    yrs_in_business character varying,
    num_partners integer,
    num_full_time_employees integer,
    num_part_time_employees integer,
    annual_revenue character varying,
    annual_payroll character varying,
    seasonal_business boolean DEFAULT false,
    num_subsidiaries integer,
    general_liability boolean,
    commercial_auto boolean,
    commercial_property boolean,
    professional_liability boolean,
    directors_officers_liability boolean,
    business_owners_package boolean,
    workers_comp boolean,
    commercial_crime boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_business_entities OWNER TO postgres;

--
-- TOC entry 465 (class 1259 OID 94270)
-- Name: lead_business_entities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_business_entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_business_entities_id_seq OWNER TO postgres;

--
-- TOC entry 7759 (class 0 OID 0)
-- Dependencies: 465
-- Name: lead_business_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_business_entities_id_seq OWNED BY public.lead_business_entities.id;


--
-- TOC entry 466 (class 1259 OID 94272)
-- Name: lead_campaign_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_campaign_settings (
    id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    emails text[] DEFAULT '{}'::text[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    account_id bigint NOT NULL,
    throttle integer DEFAULT 0,
    exclusive boolean,
    weekend_discount numeric(5,2) DEFAULT 0.0,
    pausable boolean DEFAULT false NOT NULL,
    email_opted_out boolean DEFAULT false NOT NULL,
    bypass_check boolean DEFAULT false NOT NULL
);


ALTER TABLE public.lead_campaign_settings OWNER TO postgres;

--
-- TOC entry 467 (class 1259 OID 94284)
-- Name: lead_campaign_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_campaign_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_campaign_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7760 (class 0 OID 0)
-- Dependencies: 467
-- Name: lead_campaign_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_campaign_settings_id_seq OWNED BY public.lead_campaign_settings.id;


--
-- TOC entry 468 (class 1259 OID 94286)
-- Name: lead_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_details (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    first_name character varying,
    last_name character varying,
    address character varying,
    city character varying,
    state character varying,
    county character varying,
    zip character varying,
    email character varying,
    phone character varying,
    aid character varying,
    cid character varying,
    sid character varying,
    session_id character varying,
    ip_address character varying,
    insured boolean,
    insco character varying,
    continuous_insurance character varying,
    policy_expiration_dt date,
    requested_coverage character varying,
    coverage_amount numeric(10,2),
    own_home boolean,
    residence_type character varying,
    device_type character varying,
    user_agent character varying,
    jornaya_lead_id character varying,
    trusted_form_token character varying,
    household_size integer,
    household_income numeric(10,2),
    qualifying_life_event boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    bankruptcy boolean,
    bi_per_person numeric(12,2),
    bi_per_incident numeric(12,2),
    consent_certificate_id character varying
);


ALTER TABLE public.lead_details OWNER TO postgres;

--
-- TOC entry 469 (class 1259 OID 94292)
-- Name: lead_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_details_id_seq OWNER TO postgres;

--
-- TOC entry 7761 (class 0 OID 0)
-- Dependencies: 469
-- Name: lead_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_details_id_seq OWNED BY public.lead_details.id;


--
-- TOC entry 470 (class 1259 OID 94294)
-- Name: lead_homes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_homes (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    address character varying,
    city character varying,
    county character varying,
    state character varying,
    zip character varying,
    residence_type character varying,
    year_built character varying,
    sq_ft character varying,
    num_bedrooms character varying,
    num_bathrooms character varying,
    garage_type character varying,
    construction_type character varying,
    foundation_type character varying,
    roof_type character varying,
    roof_age character varying,
    roof_update_dt date,
    dangerous_dogs boolean,
    dog_breed character varying,
    num_stories character varying,
    purchase_dt date,
    num_residents integer,
    new_purchase boolean,
    interior_wall_type character varying,
    exterior_wall_type character varying,
    interior_floor_type character varying,
    wiring_type character varying,
    electric_type character varying,
    heating_type character varying,
    ac_type character varying,
    num_fireplaces integer,
    swimming_pool boolean,
    trampoline boolean,
    fire_station_distance character varying,
    fire_hydrant_distance character varying,
    burglar_alarm boolean,
    fire_alarm boolean,
    smoke_alarm boolean,
    flood_zone boolean,
    house_value numeric(12,2),
    requested_coverage_amt numeric(12,2),
    personal_property_amt numeric(12,2),
    deductible numeric(10,2),
    personal_liab_amt numeric(12,2),
    med_pay_amt numeric(12,2),
    loss_of_use_amt numeric(12,2),
    earthquake_coverage boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_homes OWNER TO postgres;

--
-- TOC entry 471 (class 1259 OID 94300)
-- Name: lead_homes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_homes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_homes_id_seq OWNER TO postgres;

--
-- TOC entry 7762 (class 0 OID 0)
-- Dependencies: 471
-- Name: lead_homes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_homes_id_seq OWNED BY public.lead_homes.id;


--
-- TOC entry 472 (class 1259 OID 94302)
-- Name: lead_integration_failure_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_integration_failure_reasons (
    id bigint NOT NULL,
    lead_integration_id integer,
    name character varying,
    failure_regex character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_integration_failure_reasons OWNER TO postgres;

--
-- TOC entry 473 (class 1259 OID 94308)
-- Name: lead_integration_failure_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_integration_failure_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_integration_failure_reasons_id_seq OWNER TO postgres;

--
-- TOC entry 7763 (class 0 OID 0)
-- Dependencies: 473
-- Name: lead_integration_failure_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_integration_failure_reasons_id_seq OWNED BY public.lead_integration_failure_reasons.id;


--
-- TOC entry 474 (class 1259 OID 94310)
-- Name: lead_integration_macro_mappings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_integration_macro_mappings (
    id bigint NOT NULL,
    lead_integration_macro_id bigint NOT NULL,
    input_value character varying,
    output_value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_integration_macro_mappings OWNER TO postgres;

--
-- TOC entry 475 (class 1259 OID 94316)
-- Name: lead_integration_macro_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_integration_macro_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_integration_macro_mappings_id_seq OWNER TO postgres;

--
-- TOC entry 7764 (class 0 OID 0)
-- Dependencies: 475
-- Name: lead_integration_macro_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_integration_macro_mappings_id_seq OWNED BY public.lead_integration_macro_mappings.id;


--
-- TOC entry 476 (class 1259 OID 94318)
-- Name: lead_integration_macros; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_integration_macros (
    id bigint NOT NULL,
    lead_integration_id bigint NOT NULL,
    sf_lead_integration_macro_id bigint NOT NULL,
    key character varying,
    display_key character varying,
    encoding_type character varying,
    default_value text,
    is_custom_mapping_active boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    parent_macro_id bigint,
    has_sub_macros boolean,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_integration_macros OWNER TO postgres;

--
-- TOC entry 477 (class 1259 OID 94324)
-- Name: lead_integration_macros_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_integration_macros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_integration_macros_id_seq OWNER TO postgres;

--
-- TOC entry 7765 (class 0 OID 0)
-- Dependencies: 477
-- Name: lead_integration_macros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_integration_macros_id_seq OWNED BY public.lead_integration_macros.id;


--
-- TOC entry 478 (class 1259 OID 94326)
-- Name: lead_integration_req_headers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_integration_req_headers (
    id bigint NOT NULL,
    lead_integration_id bigint NOT NULL,
    key character varying,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_integration_req_headers OWNER TO postgres;

--
-- TOC entry 479 (class 1259 OID 94332)
-- Name: lead_integration_req_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_integration_req_headers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_integration_req_headers_id_seq OWNER TO postgres;

--
-- TOC entry 7766 (class 0 OID 0)
-- Dependencies: 479
-- Name: lead_integration_req_headers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_integration_req_headers_id_seq OWNED BY public.lead_integration_req_headers.id;


--
-- TOC entry 480 (class 1259 OID 94334)
-- Name: lead_integration_req_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_integration_req_logs (
    id bigint NOT NULL,
    lead_integration_id bigint NOT NULL,
    posting_url character varying,
    req_method character varying,
    req_body text,
    req_headers text,
    req_params character varying,
    res_status integer,
    res_body text,
    res_headers text,
    success boolean,
    is_test boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    campaign_id bigint,
    account_id bigint,
    lead_id bigint,
    email character varying,
    phone character varying,
    lead_integration_failure_reason_id integer
);


ALTER TABLE public.lead_integration_req_logs OWNER TO postgres;

--
-- TOC entry 481 (class 1259 OID 94340)
-- Name: lead_integration_req_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_integration_req_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_integration_req_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7767 (class 0 OID 0)
-- Dependencies: 481
-- Name: lead_integration_req_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_integration_req_logs_id_seq OWNED BY public.lead_integration_req_logs.id;


--
-- TOC entry 482 (class 1259 OID 94342)
-- Name: lead_integration_req_payloads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_integration_req_payloads (
    id bigint NOT NULL,
    lead_type_id bigint NOT NULL,
    lead_integration_id bigint NOT NULL,
    data text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.lead_integration_req_payloads OWNER TO postgres;

--
-- TOC entry 483 (class 1259 OID 94348)
-- Name: lead_integration_req_payloads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_integration_req_payloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_integration_req_payloads_id_seq OWNER TO postgres;

--
-- TOC entry 7768 (class 0 OID 0)
-- Dependencies: 483
-- Name: lead_integration_req_payloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_integration_req_payloads_id_seq OWNED BY public.lead_integration_req_payloads.id;


--
-- TOC entry 484 (class 1259 OID 94350)
-- Name: lead_integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_integrations (
    id bigint NOT NULL,
    account_id bigint,
    name character varying,
    req_method character varying,
    req_content_type character varying,
    posting_url character varying,
    req_type character varying,
    res_type character varying,
    res_success_regex character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    status character varying,
    accept_reject boolean DEFAULT false NOT NULL,
    priority integer,
    ui_lead_type_id bigint,
    req_timeout integer DEFAULT 30,
    is_template boolean DEFAULT false NOT NULL,
    is_ping boolean DEFAULT false,
    ping_pii boolean DEFAULT false,
    ping_config text,
    has_created_template boolean DEFAULT false,
    phase character varying,
    syndi_click boolean,
    prefill boolean DEFAULT false,
    is_intermediate boolean DEFAULT false,
    response_parser_function_id bigint,
    product_type_id bigint
);


ALTER TABLE public.lead_integrations OWNER TO postgres;

--
-- TOC entry 485 (class 1259 OID 94364)
-- Name: lead_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_integrations_id_seq OWNER TO postgres;

--
-- TOC entry 7769 (class 0 OID 0)
-- Dependencies: 485
-- Name: lead_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_integrations_id_seq OWNED BY public.lead_integrations.id;


--
-- TOC entry 486 (class 1259 OID 94366)
-- Name: lead_listings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_listings (
    id bigint NOT NULL,
    lead_ping_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    ad_group_id bigint NOT NULL,
    brand_id bigint NOT NULL,
    account_id bigint NOT NULL,
    carrier_id bigint,
    license_num character varying,
    payout numeric(10,2),
    est_payout numeric(10,2),
    bid_id character varying,
    "position" integer,
    selected boolean,
    de_duped boolean,
    excluded boolean,
    posted boolean,
    post_accepted boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    post_payout numeric(10,2),
    buyer character varying,
    listing_type character varying,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    state character varying,
    lead_type_id integer,
    source_type_id integer,
    ping_post boolean DEFAULT false,
    pp_ping_id character varying,
    pp_bid_id character varying
);


ALTER TABLE public.lead_listings OWNER TO postgres;

--
-- TOC entry 487 (class 1259 OID 94373)
-- Name: lead_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_listings_id_seq OWNER TO postgres;

--
-- TOC entry 7770 (class 0 OID 0)
-- Dependencies: 487
-- Name: lead_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_listings_id_seq OWNED BY public.lead_listings.id;


--
-- TOC entry 488 (class 1259 OID 94375)
-- Name: lead_opportunities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_opportunities (
    id bigint NOT NULL,
    lead_ping_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    ad_group_id bigint NOT NULL,
    brand_id bigint NOT NULL,
    account_id bigint NOT NULL,
    payout numeric(10,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone
);


ALTER TABLE public.lead_opportunities OWNER TO postgres;

--
-- TOC entry 489 (class 1259 OID 94378)
-- Name: lead_opportunities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_opportunities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_opportunities_id_seq OWNER TO postgres;

--
-- TOC entry 7771 (class 0 OID 0)
-- Dependencies: 489
-- Name: lead_opportunities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_opportunities_id_seq OWNED BY public.lead_opportunities.id;


--
-- TOC entry 490 (class 1259 OID 94380)
-- Name: lead_ping_debug_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_ping_debug_logs (
    id bigint NOT NULL,
    lead_ping_id bigint NOT NULL,
    log text,
    response_time_ms integer,
    num_listings integer,
    token character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.lead_ping_debug_logs OWNER TO postgres;

--
-- TOC entry 491 (class 1259 OID 94386)
-- Name: lead_ping_debug_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_ping_debug_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_ping_debug_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7772 (class 0 OID 0)
-- Dependencies: 491
-- Name: lead_ping_debug_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_ping_debug_logs_id_seq OWNED BY public.lead_ping_debug_logs.id;


--
-- TOC entry 492 (class 1259 OID 94388)
-- Name: lead_ping_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_ping_details (
    id bigint NOT NULL,
    lead_ping_id bigint NOT NULL,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age integer,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    phone character varying,
    email character varying,
    city character varying,
    county character varying,
    tobacco boolean,
    major_health_conditions boolean,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    jornaya_lead_id character varying,
    trusted_form_token character varying,
    col1 character varying,
    col2 character varying,
    col3 character varying,
    col4 character varying,
    col5 character varying,
    col6 character varying,
    col7 character varying,
    col8 character varying,
    col9 character varying,
    col10 character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.lead_ping_details OWNER TO postgres;

--
-- TOC entry 493 (class 1259 OID 94394)
-- Name: lead_ping_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_ping_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_ping_details_id_seq OWNER TO postgres;

--
-- TOC entry 7773 (class 0 OID 0)
-- Dependencies: 493
-- Name: lead_ping_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_ping_details_id_seq OWNED BY public.lead_ping_details.id;


--
-- TOC entry 494 (class 1259 OID 94396)
-- Name: lead_ping_matches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_ping_matches (
    id bigint NOT NULL,
    lead_ping_id integer,
    account_id integer,
    campaign_id integer,
    ad_group_id integer,
    brand_id integer,
    ad_group_active boolean,
    payout numeric(10,2),
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.lead_ping_matches OWNER TO postgres;

--
-- TOC entry 495 (class 1259 OID 94399)
-- Name: lead_ping_matches_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_ping_matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_ping_matches_id_seq OWNER TO postgres;

--
-- TOC entry 7774 (class 0 OID 0)
-- Dependencies: 495
-- Name: lead_ping_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_ping_matches_id_seq OWNED BY public.lead_ping_matches.id;


--
-- TOC entry 496 (class 1259 OID 94401)
-- Name: lead_pings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_pings (
    id bigint NOT NULL,
    partner_id character varying,
    lead_type_id bigint NOT NULL,
    aid character varying,
    cid character varying,
    sid character varying,
    ks character varying,
    session_id character varying,
    zip character varying,
    state character varying,
    device_type character varying,
    source_type_id bigint,
    form_type_id bigint,
    lead_data text,
    total_opportunities integer,
    total_listings integer,
    total_revenue numeric(10,2),
    total_cost numeric(10,2),
    uid character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.lead_pings OWNER TO postgres;

--
-- TOC entry 497 (class 1259 OID 94407)
-- Name: lead_pings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_pings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_pings_id_seq OWNER TO postgres;

--
-- TOC entry 7775 (class 0 OID 0)
-- Dependencies: 497
-- Name: lead_pings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_pings_id_seq OWNED BY public.lead_pings.id;


--
-- TOC entry 498 (class 1259 OID 94409)
-- Name: lead_post_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_post_details (
    id bigint NOT NULL,
    lead_post_id bigint NOT NULL,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age integer,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    phone character varying,
    email character varying,
    city character varying,
    county character varying,
    tobacco boolean,
    major_health_conditions boolean,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    jornaya_lead_id character varying,
    trusted_form_token character varying,
    col1 character varying,
    col2 character varying,
    col3 character varying,
    col4 character varying,
    col5 character varying,
    col6 character varying,
    col7 character varying,
    col8 character varying,
    col9 character varying,
    col10 character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.lead_post_details OWNER TO postgres;

--
-- TOC entry 499 (class 1259 OID 94415)
-- Name: lead_post_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_post_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_post_details_id_seq OWNER TO postgres;

--
-- TOC entry 7776 (class 0 OID 0)
-- Dependencies: 499
-- Name: lead_post_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_post_details_id_seq OWNED BY public.lead_post_details.id;


--
-- TOC entry 500 (class 1259 OID 94417)
-- Name: lead_post_legs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_post_legs (
    id bigint NOT NULL,
    lead_post_id bigint NOT NULL,
    bid_id character varying,
    accepted boolean,
    payout numeric(10,2),
    refunded boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    msg text
);


ALTER TABLE public.lead_post_legs OWNER TO postgres;

--
-- TOC entry 501 (class 1259 OID 94423)
-- Name: lead_post_legs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_post_legs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_post_legs_id_seq OWNER TO postgres;

--
-- TOC entry 7777 (class 0 OID 0)
-- Dependencies: 501
-- Name: lead_post_legs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_post_legs_id_seq OWNED BY public.lead_post_legs.id;


--
-- TOC entry 502 (class 1259 OID 94425)
-- Name: lead_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_posts (
    id bigint NOT NULL,
    lead_ping_id bigint NOT NULL,
    partner_id character varying,
    lead_type_id bigint NOT NULL,
    zip character varying,
    state character varying,
    accepted boolean,
    num_legs integer,
    accepted_legs integer,
    cost numeric(10,2),
    revenue numeric(10,2),
    refunded boolean,
    data text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    uid character varying,
    post_response text
);


ALTER TABLE public.lead_posts OWNER TO postgres;

--
-- TOC entry 503 (class 1259 OID 94431)
-- Name: lead_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_posts_id_seq OWNER TO postgres;

--
-- TOC entry 7778 (class 0 OID 0)
-- Dependencies: 503
-- Name: lead_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_posts_id_seq OWNED BY public.lead_posts.id;


--
-- TOC entry 504 (class 1259 OID 94433)
-- Name: lead_prices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_prices (
    id bigint NOT NULL,
    price numeric,
    shared boolean DEFAULT false,
    lead_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.lead_prices OWNER TO postgres;

--
-- TOC entry 505 (class 1259 OID 94440)
-- Name: lead_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_prices_id_seq OWNER TO postgres;

--
-- TOC entry 7779 (class 0 OID 0)
-- Dependencies: 505
-- Name: lead_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_prices_id_seq OWNED BY public.lead_prices.id;


--
-- TOC entry 506 (class 1259 OID 94442)
-- Name: lead_refund_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_refund_reasons (
    id bigint NOT NULL,
    cap integer,
    reason character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_refund_reasons OWNER TO postgres;

--
-- TOC entry 507 (class 1259 OID 94448)
-- Name: lead_refund_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_refund_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_refund_reasons_id_seq OWNER TO postgres;

--
-- TOC entry 7780 (class 0 OID 0)
-- Dependencies: 507
-- Name: lead_refund_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_refund_reasons_id_seq OWNED BY public.lead_refund_reasons.id;


--
-- TOC entry 508 (class 1259 OID 94450)
-- Name: lead_refunds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_refunds (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    refund_requestor_name character varying,
    refund_requester_phone character varying,
    comments text,
    status character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    user_id bigint NOT NULL,
    lead_refund_reason_id integer,
    approved_by integer
);


ALTER TABLE public.lead_refunds OWNER TO postgres;

--
-- TOC entry 509 (class 1259 OID 94456)
-- Name: lead_refunds_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_refunds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_refunds_id_seq OWNER TO postgres;

--
-- TOC entry 7781 (class 0 OID 0)
-- Dependencies: 509
-- Name: lead_refunds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_refunds_id_seq OWNED BY public.lead_refunds.id;


--
-- TOC entry 510 (class 1259 OID 94458)
-- Name: lead_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_types (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying
);


ALTER TABLE public.lead_types OWNER TO postgres;

--
-- TOC entry 511 (class 1259 OID 94464)
-- Name: lead_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_types_id_seq OWNER TO postgres;

--
-- TOC entry 7782 (class 0 OID 0)
-- Dependencies: 511
-- Name: lead_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_types_id_seq OWNED BY public.lead_types.id;


--
-- TOC entry 512 (class 1259 OID 94466)
-- Name: lead_vehicles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_vehicles (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    lead_applicant_id bigint NOT NULL,
    vin character varying,
    year character varying,
    make character varying,
    model character varying,
    sub_model character varying,
    ownership_status character varying,
    primary_use character varying,
    daily_mileage integer,
    annual_mileage integer,
    days_driven integer,
    salvaged boolean DEFAULT false,
    full_coverage boolean,
    comp_ded integer,
    coll_ded integer,
    liab_limits character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    garage_type character varying,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_vehicles OWNER TO postgres;

--
-- TOC entry 513 (class 1259 OID 94473)
-- Name: lead_vehicles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_vehicles_id_seq OWNER TO postgres;

--
-- TOC entry 7783 (class 0 OID 0)
-- Dependencies: 513
-- Name: lead_vehicles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_vehicles_id_seq OWNED BY public.lead_vehicles.id;


--
-- TOC entry 514 (class 1259 OID 94475)
-- Name: lead_violations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead_violations (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    lead_applicant_id bigint NOT NULL,
    violation_type_id bigint NOT NULL,
    dt date,
    "desc" character varying,
    paid_amount numeric(10,2),
    damage_type character varying,
    at_fault boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.lead_violations OWNER TO postgres;

--
-- TOC entry 515 (class 1259 OID 94481)
-- Name: lead_violations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_violations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_violations_id_seq OWNER TO postgres;

--
-- TOC entry 7784 (class 0 OID 0)
-- Dependencies: 515
-- Name: lead_violations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_violations_id_seq OWNED BY public.lead_violations.id;


--
-- TOC entry 516 (class 1259 OID 94483)
-- Name: leads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leads (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    lead_type_id bigint NOT NULL,
    product_type_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    disposition character varying
);


ALTER TABLE public.leads OWNER TO postgres;

--
-- TOC entry 517 (class 1259 OID 94489)
-- Name: leads_customize_columns_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leads_customize_columns_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    lead_name integer DEFAULT 0,
    lead_phone integer DEFAULT 0,
    lead_email integer DEFAULT 0,
    lead_state integer DEFAULT 0,
    lead_type integer DEFAULT 0,
    lead_created_at integer DEFAULT 0,
    lead_brand integer DEFAULT 0,
    lead_campaign_name integer DEFAULT 0,
    lead_status integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lead_refund_status integer DEFAULT 0,
    lead_cost integer DEFAULT 0
);


ALTER TABLE public.leads_customize_columns_orders OWNER TO postgres;

--
-- TOC entry 518 (class 1259 OID 94503)
-- Name: leads_customize_columns_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.leads_customize_columns_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leads_customize_columns_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7785 (class 0 OID 0)
-- Dependencies: 518
-- Name: leads_customize_columns_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.leads_customize_columns_orders_id_seq OWNED BY public.leads_customize_columns_orders.id;


--
-- TOC entry 519 (class 1259 OID 94505)
-- Name: leads_dashboard_customize_column_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leads_dashboard_customize_column_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    state_opportunities integer DEFAULT 0,
    state_searches integer DEFAULT 0,
    state_leads integer DEFAULT 0,
    state_won integer DEFAULT 0,
    state_cost integer DEFAULT 0,
    state_avg_cpl integer DEFAULT 0,
    campaign_opportunities integer DEFAULT 0,
    campaign_searches integer DEFAULT 0,
    campaign_leads integer DEFAULT 0,
    campaign_won integer DEFAULT 0,
    campaign_cost integer DEFAULT 0,
    campaign_avg_cpl integer DEFAULT 0,
    insurance_type_opportunities integer DEFAULT 0,
    insurance_type_searches integer DEFAULT 0,
    insurance_type_bid_rate integer DEFAULT 0,
    insurance_type_won integer DEFAULT 0,
    insurance_type_leads integer DEFAULT 0,
    insurance_type_cost integer DEFAULT 0,
    insurance_type_avg_cpl integer DEFAULT 0,
    state_bid_rate integer DEFAULT 0,
    state_accept_rate integer DEFAULT 0,
    state_avg_bid integer DEFAULT 0,
    campaign_bid_rate integer DEFAULT 0,
    campaign_accept_rate integer DEFAULT 0,
    campaign_avg_bid integer DEFAULT 0,
    insurance_type_avg_bid integer DEFAULT 0,
    insurance_type_accept_rate integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.leads_dashboard_customize_column_orders OWNER TO postgres;

--
-- TOC entry 520 (class 1259 OID 94535)
-- Name: leads_dashboard_customize_column_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.leads_dashboard_customize_column_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leads_dashboard_customize_column_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7786 (class 0 OID 0)
-- Dependencies: 520
-- Name: leads_dashboard_customize_column_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.leads_dashboard_customize_column_orders_id_seq OWNED BY public.leads_dashboard_customize_column_orders.id;


--
-- TOC entry 521 (class 1259 OID 94537)
-- Name: leads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leads_id_seq OWNER TO postgres;

--
-- TOC entry 7787 (class 0 OID 0)
-- Dependencies: 521
-- Name: leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.leads_id_seq OWNED BY public.leads.id;


--
-- TOC entry 522 (class 1259 OID 94539)
-- Name: memberships; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.memberships (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.memberships OWNER TO postgres;

--
-- TOC entry 523 (class 1259 OID 94542)
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.memberships_id_seq OWNER TO postgres;

--
-- TOC entry 7788 (class 0 OID 0)
-- Dependencies: 523
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.memberships_id_seq OWNED BY public.memberships.id;


--
-- TOC entry 524 (class 1259 OID 94544)
-- Name: mv_refresh_statuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mv_refresh_statuses (
    id bigint NOT NULL,
    status character varying NOT NULL,
    name character varying,
    transaction_id character varying,
    db_name character varying,
    mv_id character varying,
    refresh_type character varying,
    start_time timestamp(6) without time zone NOT NULL,
    end_time timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jira_key character varying
);


ALTER TABLE public.mv_refresh_statuses OWNER TO postgres;

--
-- TOC entry 525 (class 1259 OID 94551)
-- Name: mv_refresh_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mv_refresh_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mv_refresh_statuses_id_seq OWNER TO postgres;

--
-- TOC entry 7789 (class 0 OID 0)
-- Dependencies: 525
-- Name: mv_refresh_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mv_refresh_statuses_id_seq OWNED BY public.mv_refresh_statuses.id;


--
-- TOC entry 526 (class 1259 OID 94553)
-- Name: non_rtb_ping_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.non_rtb_ping_stats (
    id bigint NOT NULL,
    product_type_id integer,
    ping_id integer,
    lead_type_id integer,
    account_id integer,
    brand_id integer,
    campaign_id integer,
    ad_group_id integer,
    account_manager_id integer,
    sales_rep_id integer,
    carrier_id integer,
    billing_type_id integer,
    match boolean,
    opportunity boolean,
    listing boolean,
    won boolean,
    accepted boolean,
    listing_id integer,
    bid numeric(10,2),
    de_duped boolean,
    excluded boolean,
    device_type character varying,
    mobile boolean,
    zip character varying,
    state character varying,
    source_type_id integer,
    active_source boolean,
    aid character varying,
    cid character varying,
    billed_at timestamp(6) without time zone,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    insured boolean,
    continuous_coverage character varying,
    home_owner boolean,
    gender character varying,
    marital_status character varying,
    consumer_age character varying,
    education character varying,
    credit_rating character varying,
    military_affiliation boolean,
    num_drivers integer,
    num_vehicles integer,
    violations boolean,
    dui boolean,
    accidents boolean,
    license_status character varying,
    first_name character varying,
    last_name character varying,
    email character varying,
    phone character varying,
    city character varying,
    county character varying,
    tobacco boolean,
    major_health_conditions boolean,
    life_coverage_type character varying,
    life_coverage_amount character varying,
    property_type character varying,
    property_age character varying,
    years_in_business character varying,
    commercial_coverage_type character varying,
    household_income character varying,
    ip_address character varying,
    disqualification_reason character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.non_rtb_ping_stats OWNER TO postgres;

--
-- TOC entry 527 (class 1259 OID 94559)
-- Name: non_rtb_ping_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.non_rtb_ping_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.non_rtb_ping_stats_id_seq OWNER TO postgres;

--
-- TOC entry 7790 (class 0 OID 0)
-- Dependencies: 527
-- Name: non_rtb_ping_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.non_rtb_ping_stats_id_seq OWNED BY public.non_rtb_ping_stats.id;


--
-- TOC entry 528 (class 1259 OID 94561)
-- Name: notification_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_events (
    id bigint NOT NULL,
    channel character varying,
    name character varying,
    source_id bigint,
    send_time timestamp(6) without time zone,
    status character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint,
    brand_id bigint
);


ALTER TABLE public.notification_events OWNER TO postgres;

--
-- TOC entry 529 (class 1259 OID 94567)
-- Name: notification_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_events_id_seq OWNER TO postgres;

--
-- TOC entry 7791 (class 0 OID 0)
-- Dependencies: 529
-- Name: notification_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_events_id_seq OWNED BY public.notification_events.id;


--
-- TOC entry 530 (class 1259 OID 94569)
-- Name: notification_job_sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_job_sources (
    id bigint NOT NULL,
    src_type character varying,
    data text,
    account_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.notification_job_sources OWNER TO postgres;

--
-- TOC entry 531 (class 1259 OID 94575)
-- Name: notification_job_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_job_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_job_sources_id_seq OWNER TO postgres;

--
-- TOC entry 7792 (class 0 OID 0)
-- Dependencies: 531
-- Name: notification_job_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_job_sources_id_seq OWNED BY public.notification_job_sources.id;


--
-- TOC entry 532 (class 1259 OID 94577)
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_preferences (
    id bigint NOT NULL,
    subscriptions text[] DEFAULT '{}'::text[],
    notification_emails text[] DEFAULT '{}'::text[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint,
    brand_id bigint,
    user_id bigint
);


ALTER TABLE public.notification_preferences OWNER TO postgres;

--
-- TOC entry 533 (class 1259 OID 94585)
-- Name: notification_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_preferences_id_seq OWNER TO postgres;

--
-- TOC entry 7793 (class 0 OID 0)
-- Dependencies: 533
-- Name: notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_preferences_id_seq OWNED BY public.notification_preferences.id;


--
-- TOC entry 534 (class 1259 OID 94587)
-- Name: old_passwords; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.old_passwords (
    id bigint NOT NULL,
    encrypted_password character varying NOT NULL,
    password_archivable_type character varying NOT NULL,
    password_archivable_id integer NOT NULL,
    created_at timestamp(6) without time zone
);


ALTER TABLE public.old_passwords OWNER TO postgres;

--
-- TOC entry 535 (class 1259 OID 94593)
-- Name: old_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.old_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.old_passwords_id_seq OWNER TO postgres;

--
-- TOC entry 7794 (class 0 OID 0)
-- Dependencies: 535
-- Name: old_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.old_passwords_id_seq OWNED BY public.old_passwords.id;


--
-- TOC entry 536 (class 1259 OID 94595)
-- Name: page_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.page_groups (
    id bigint NOT NULL,
    quote_funnel_id bigint NOT NULL,
    "order" integer,
    is_repeatable boolean DEFAULT false,
    repetitive_field_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.page_groups OWNER TO postgres;

--
-- TOC entry 537 (class 1259 OID 94602)
-- Name: page_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.page_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.page_groups_id_seq OWNER TO postgres;

--
-- TOC entry 7795 (class 0 OID 0)
-- Dependencies: 537
-- Name: page_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.page_groups_id_seq OWNED BY public.page_groups.id;


--
-- TOC entry 538 (class 1259 OID 94604)
-- Name: pages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pages (
    id bigint NOT NULL,
    quote_funnel_id bigint NOT NULL,
    page_group_id bigint NOT NULL,
    "order" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.pages OWNER TO postgres;

--
-- TOC entry 539 (class 1259 OID 94607)
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pages_id_seq OWNER TO postgres;

--
-- TOC entry 7796 (class 0 OID 0)
-- Dependencies: 539
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pages_id_seq OWNED BY public.pages.id;


--
-- TOC entry 540 (class 1259 OID 94609)
-- Name: payment_terms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_terms (
    id bigint NOT NULL,
    name character varying DEFAULT 'null'::character varying,
    description text,
    active boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.payment_terms OWNER TO postgres;

--
-- TOC entry 541 (class 1259 OID 94616)
-- Name: payment_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_terms_id_seq OWNER TO postgres;

--
-- TOC entry 7797 (class 0 OID 0)
-- Dependencies: 541
-- Name: payment_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_terms_id_seq OWNED BY public.payment_terms.id;


--
-- TOC entry 542 (class 1259 OID 94618)
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id bigint NOT NULL,
    can_create boolean DEFAULT false NOT NULL,
    can_read boolean DEFAULT false NOT NULL,
    can_update boolean DEFAULT false NOT NULL,
    can_delete boolean DEFAULT false NOT NULL,
    feature_id bigint NOT NULL,
    role_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- TOC entry 543 (class 1259 OID 94625)
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permissions_id_seq OWNER TO postgres;

--
-- TOC entry 7798 (class 0 OID 0)
-- Dependencies: 543
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- TOC entry 544 (class 1259 OID 94627)
-- Name: platform_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.platform_settings (
    id bigint NOT NULL,
    retail_clicks_enabled boolean DEFAULT false,
    retail_source_settings_enabled boolean DEFAULT false,
    retail_pixel_conversion_settings_enabled boolean DEFAULT false,
    retail_profiles_enabled boolean DEFAULT false,
    retail_metrics_enabled boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    retail_targeting_packages_enabled boolean DEFAULT true
);


ALTER TABLE public.platform_settings OWNER TO postgres;

--
-- TOC entry 545 (class 1259 OID 94636)
-- Name: platform_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.platform_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.platform_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7799 (class 0 OID 0)
-- Dependencies: 545
-- Name: platform_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.platform_settings_id_seq OWNED BY public.platform_settings.id;


--
-- TOC entry 546 (class 1259 OID 94638)
-- Name: popup_lead_type_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.popup_lead_type_messages (
    id bigint NOT NULL,
    lead_type_id bigint NOT NULL,
    agent_profile_id bigint NOT NULL,
    message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.popup_lead_type_messages OWNER TO postgres;

--
-- TOC entry 547 (class 1259 OID 94644)
-- Name: popup_lead_type_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.popup_lead_type_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.popup_lead_type_messages_id_seq OWNER TO postgres;

--
-- TOC entry 7800 (class 0 OID 0)
-- Dependencies: 547
-- Name: popup_lead_type_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.popup_lead_type_messages_id_seq OWNED BY public.popup_lead_type_messages.id;


--
-- TOC entry 548 (class 1259 OID 94646)
-- Name: postback_url_req_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.postback_url_req_logs (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    postback_url text,
    req_url text,
    req_method character varying,
    res_headers text,
    res_body text,
    res_status integer,
    click_id character varying,
    click_listing_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.postback_url_req_logs OWNER TO postgres;

--
-- TOC entry 549 (class 1259 OID 94652)
-- Name: postback_url_req_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.postback_url_req_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.postback_url_req_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7801 (class 0 OID 0)
-- Dependencies: 549
-- Name: postback_url_req_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.postback_url_req_logs_id_seq OWNED BY public.postback_url_req_logs.id;


--
-- TOC entry 550 (class 1259 OID 94654)
-- Name: pp_ping_report_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pp_ping_report_accounts (
    id bigint NOT NULL,
    account_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.pp_ping_report_accounts OWNER TO postgres;

--
-- TOC entry 551 (class 1259 OID 94657)
-- Name: pp_ping_report_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pp_ping_report_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pp_ping_report_accounts_id_seq OWNER TO postgres;

--
-- TOC entry 7802 (class 0 OID 0)
-- Dependencies: 551
-- Name: pp_ping_report_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pp_ping_report_accounts_id_seq OWNED BY public.pp_ping_report_accounts.id;


--
-- TOC entry 552 (class 1259 OID 94659)
-- Name: prefill_queries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prefill_queries (
    id bigint NOT NULL,
    account_id bigint,
    campaign_id bigint,
    quote_funnel_id bigint,
    old_data text,
    new_data text,
    converted boolean,
    lead_id bigint,
    session_id character varying,
    click_id character varying,
    started boolean,
    all_fields_prefilled boolean,
    prefill_perc numeric(5,2),
    missing_fields text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    phone_num character varying,
    state character varying,
    ad_id integer,
    source_type_id integer,
    lead_type_id integer,
    ad_group_id integer,
    brand_id bigint,
    click_ping_id integer,
    product_type_id integer,
    preview boolean DEFAULT false
);


ALTER TABLE public.prefill_queries OWNER TO postgres;

--
-- TOC entry 553 (class 1259 OID 94666)
-- Name: prefill_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prefill_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prefill_queries_id_seq OWNER TO postgres;

--
-- TOC entry 7803 (class 0 OID 0)
-- Dependencies: 553
-- Name: prefill_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prefill_queries_id_seq OWNED BY public.prefill_queries.id;


--
-- TOC entry 554 (class 1259 OID 94668)
-- Name: product_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_types (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying
);


ALTER TABLE public.product_types OWNER TO postgres;

--
-- TOC entry 555 (class 1259 OID 94674)
-- Name: product_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_types_id_seq OWNER TO postgres;

--
-- TOC entry 7804 (class 0 OID 0)
-- Dependencies: 555
-- Name: product_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_types_id_seq OWNED BY public.product_types.id;


--
-- TOC entry 556 (class 1259 OID 94676)
-- Name: prospects_customize_columns_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prospects_customize_columns_orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    prospect_name integer DEFAULT 0,
    prospect_phone integer DEFAULT 0,
    prospect_email integer DEFAULT 0,
    prospect_campaign_name integer DEFAULT 0,
    prospect_type integer DEFAULT 0,
    prospect_ad_group integer DEFAULT 0,
    prospect_brand integer DEFAULT 0,
    prospect_disposition integer DEFAULT 0,
    prospect_insured integer DEFAULT 0,
    prospect_address integer DEFAULT 0,
    prospect_city integer DEFAULT 0,
    prospect_zip_code integer DEFAULT 0,
    prospect_received integer DEFAULT 0,
    prospect_applicants integer DEFAULT 0,
    prospect_vehicles integer DEFAULT 0,
    prospect_status integer DEFAULT 0,
    prospect_duration integer DEFAULT 0,
    prospect_state integer DEFAULT 0,
    prospect_recording integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.prospects_customize_columns_orders OWNER TO postgres;

--
-- TOC entry 557 (class 1259 OID 94698)
-- Name: prospects_customize_columns_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prospects_customize_columns_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prospects_customize_columns_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7805 (class 0 OID 0)
-- Dependencies: 557
-- Name: prospects_customize_columns_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prospects_customize_columns_orders_id_seq OWNED BY public.prospects_customize_columns_orders.id;


--
-- TOC entry 558 (class 1259 OID 94700)
-- Name: qf_call_integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_call_integrations (
    id bigint NOT NULL,
    campaign_id integer,
    lead_integration_id integer,
    config text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.qf_call_integrations OWNER TO postgres;

--
-- TOC entry 559 (class 1259 OID 94706)
-- Name: qf_call_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_call_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_call_integrations_id_seq OWNER TO postgres;

--
-- TOC entry 7806 (class 0 OID 0)
-- Dependencies: 559
-- Name: qf_call_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_call_integrations_id_seq OWNED BY public.qf_call_integrations.id;


--
-- TOC entry 560 (class 1259 OID 94708)
-- Name: qf_call_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_call_settings (
    id bigint NOT NULL,
    campaign_id integer,
    email_recipients jsonb,
    transfer_number character varying,
    tracking_number character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.qf_call_settings OWNER TO postgres;

--
-- TOC entry 561 (class 1259 OID 94714)
-- Name: qf_call_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_call_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_call_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7807 (class 0 OID 0)
-- Dependencies: 561
-- Name: qf_call_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_call_settings_id_seq OWNED BY public.qf_call_settings.id;


--
-- TOC entry 562 (class 1259 OID 94716)
-- Name: qf_lead_integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_lead_integrations (
    id bigint NOT NULL,
    campaign_id integer,
    lead_integration_id integer,
    config text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.qf_lead_integrations OWNER TO postgres;

--
-- TOC entry 563 (class 1259 OID 94722)
-- Name: qf_lead_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_lead_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_lead_integrations_id_seq OWNER TO postgres;

--
-- TOC entry 7808 (class 0 OID 0)
-- Dependencies: 563
-- Name: qf_lead_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_lead_integrations_id_seq OWNED BY public.qf_lead_integrations.id;


--
-- TOC entry 564 (class 1259 OID 94724)
-- Name: qf_lead_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_lead_settings (
    id bigint NOT NULL,
    campaign_id integer,
    email_recipients jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.qf_lead_settings OWNER TO postgres;

--
-- TOC entry 565 (class 1259 OID 94730)
-- Name: qf_lead_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_lead_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_lead_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7809 (class 0 OID 0)
-- Dependencies: 565
-- Name: qf_lead_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_lead_settings_id_seq OWNED BY public.qf_lead_settings.id;


--
-- TOC entry 566 (class 1259 OID 94732)
-- Name: qf_quote_call_qas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_quote_call_qas (
    id bigint NOT NULL,
    qf_quote_call_id bigint NOT NULL,
    question text,
    answer text,
    transcript_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_default boolean
);


ALTER TABLE public.qf_quote_call_qas OWNER TO postgres;

--
-- TOC entry 567 (class 1259 OID 94738)
-- Name: qf_quote_call_qas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_quote_call_qas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_quote_call_qas_id_seq OWNER TO postgres;

--
-- TOC entry 7810 (class 0 OID 0)
-- Dependencies: 567
-- Name: qf_quote_call_qas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_quote_call_qas_id_seq OWNED BY public.qf_quote_call_qas.id;


--
-- TOC entry 568 (class 1259 OID 94740)
-- Name: qf_quote_call_summaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_quote_call_summaries (
    id bigint NOT NULL,
    qf_quote_call_id bigint NOT NULL,
    prompt text,
    summary text,
    transcript_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status character varying
);


ALTER TABLE public.qf_quote_call_summaries OWNER TO postgres;

--
-- TOC entry 569 (class 1259 OID 94746)
-- Name: qf_quote_call_summaries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_quote_call_summaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_quote_call_summaries_id_seq OWNER TO postgres;

--
-- TOC entry 7811 (class 0 OID 0)
-- Dependencies: 569
-- Name: qf_quote_call_summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_quote_call_summaries_id_seq OWNED BY public.qf_quote_call_summaries.id;


--
-- TOC entry 570 (class 1259 OID 94748)
-- Name: qf_quote_call_transcriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_quote_call_transcriptions (
    id bigint NOT NULL,
    qf_quote_call_id bigint NOT NULL,
    status character varying,
    media_file_uri character varying,
    transcript_uri character varying,
    start_time timestamp(6) without time zone,
    creation_time timestamp(6) without time zone,
    completion_time timestamp(6) without time zone,
    failure_reason character varying,
    matched_categories character varying,
    total_talk_time integer,
    total_non_talk_time integer,
    agent_talk_time integer,
    consumer_talk_time integer,
    agent_interruptions integer,
    consumer_interruptions integer,
    agent_sentiment character varying,
    consumer_sentiment character varying,
    agent_talk_speed integer,
    consumer_talk_speed integer,
    agent_interruptions_count integer,
    consumer_interruptions_count integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.qf_quote_call_transcriptions OWNER TO postgres;

--
-- TOC entry 571 (class 1259 OID 94754)
-- Name: qf_quote_call_transcriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_quote_call_transcriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_quote_call_transcriptions_id_seq OWNER TO postgres;

--
-- TOC entry 7812 (class 0 OID 0)
-- Dependencies: 571
-- Name: qf_quote_call_transcriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_quote_call_transcriptions_id_seq OWNED BY public.qf_quote_call_transcriptions.id;


--
-- TOC entry 572 (class 1259 OID 94756)
-- Name: qf_quote_calls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qf_quote_calls (
    id bigint NOT NULL,
    account_id integer,
    campaign_id integer,
    call_sid character varying,
    status character varying,
    caller character varying,
    called character varying,
    direction character varying,
    shaken_stir_status character varying,
    call_duration integer,
    recording_url character varying,
    lead_type_id integer,
    charged boolean,
    price numeric(5,2),
    affiliate_id integer,
    call_rep character varying,
    refunded boolean,
    state character varying,
    lead_id integer,
    cost numeric(5,2),
    brand_id bigint,
    ad_group_id bigint,
    transfer_type character varying,
    duplicate boolean DEFAULT false NOT NULL,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    time_to_pickup numeric,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.qf_quote_calls OWNER TO postgres;

--
-- TOC entry 573 (class 1259 OID 94763)
-- Name: qf_quote_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qf_quote_calls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qf_quote_calls_id_seq OWNER TO postgres;

--
-- TOC entry 7813 (class 0 OID 0)
-- Dependencies: 573
-- Name: qf_quote_calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qf_quote_calls_id_seq OWNED BY public.qf_quote_calls.id;


--
-- TOC entry 574 (class 1259 OID 94765)
-- Name: question_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.question_groups (
    id bigint NOT NULL,
    quote_funnel_id bigint NOT NULL,
    page_group_id bigint NOT NULL,
    page_id bigint NOT NULL,
    label text,
    "order" integer,
    is_repeatable boolean DEFAULT false,
    repetitive_field_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.question_groups OWNER TO postgres;

--
-- TOC entry 575 (class 1259 OID 94772)
-- Name: question_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.question_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.question_groups_id_seq OWNER TO postgres;

--
-- TOC entry 7814 (class 0 OID 0)
-- Dependencies: 575
-- Name: question_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.question_groups_id_seq OWNED BY public.question_groups.id;


--
-- TOC entry 576 (class 1259 OID 94774)
-- Name: questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questions (
    id bigint NOT NULL,
    quote_funnel_id bigint NOT NULL,
    page_group_id bigint NOT NULL,
    page_id bigint NOT NULL,
    question_group_id bigint NOT NULL,
    question_type character varying,
    question_label text,
    placeholder character varying,
    drop_down_values text,
    required boolean DEFAULT false,
    field_name character varying,
    "order" integer,
    is_repeatable_question boolean DEFAULT false,
    repeatable_type character varying,
    depends_on character varying,
    depends_on_value character varying,
    depends_on_type character varying,
    array_field character varying,
    object_fields text,
    css text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    skip boolean DEFAULT false
);


ALTER TABLE public.questions OWNER TO postgres;

--
-- TOC entry 577 (class 1259 OID 94783)
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.questions_id_seq OWNER TO postgres;

--
-- TOC entry 7815 (class 0 OID 0)
-- Dependencies: 577
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- TOC entry 578 (class 1259 OID 94785)
-- Name: quote_call_qas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quote_call_qas (
    id bigint NOT NULL,
    quote_call_id bigint NOT NULL,
    question text,
    answer text,
    transcript_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_default boolean
);


ALTER TABLE public.quote_call_qas OWNER TO postgres;

--
-- TOC entry 579 (class 1259 OID 94791)
-- Name: quote_call_qas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quote_call_qas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quote_call_qas_id_seq OWNER TO postgres;

--
-- TOC entry 7816 (class 0 OID 0)
-- Dependencies: 579
-- Name: quote_call_qas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quote_call_qas_id_seq OWNED BY public.quote_call_qas.id;


--
-- TOC entry 580 (class 1259 OID 94793)
-- Name: quote_call_summaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quote_call_summaries (
    id bigint NOT NULL,
    quote_call_id bigint NOT NULL,
    prompt text,
    summary text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    transcript_id character varying,
    status character varying
);


ALTER TABLE public.quote_call_summaries OWNER TO postgres;

--
-- TOC entry 581 (class 1259 OID 94799)
-- Name: quote_call_summaries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quote_call_summaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quote_call_summaries_id_seq OWNER TO postgres;

--
-- TOC entry 7817 (class 0 OID 0)
-- Dependencies: 581
-- Name: quote_call_summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quote_call_summaries_id_seq OWNED BY public.quote_call_summaries.id;


--
-- TOC entry 582 (class 1259 OID 94801)
-- Name: quote_call_transcriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quote_call_transcriptions (
    id bigint NOT NULL,
    quote_call_id bigint NOT NULL,
    status character varying,
    media_file_uri character varying,
    transcript_uri character varying,
    start_time timestamp(6) without time zone,
    creation_time timestamp(6) without time zone,
    completion_time timestamp(6) without time zone,
    failure_reason character varying,
    matched_categories character varying,
    total_talk_time integer,
    total_non_talk_time integer,
    agent_talk_time integer,
    consumer_talk_time integer,
    agent_interruptions integer,
    consumer_interruptions integer,
    agent_sentiment character varying,
    consumer_sentiment character varying,
    agent_talk_speed integer,
    consumer_talk_speed integer,
    agent_interruptions_count integer,
    consumer_interruptions_count integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.quote_call_transcriptions OWNER TO postgres;

--
-- TOC entry 583 (class 1259 OID 94807)
-- Name: quote_call_transcriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quote_call_transcriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quote_call_transcriptions_id_seq OWNER TO postgres;

--
-- TOC entry 7818 (class 0 OID 0)
-- Dependencies: 583
-- Name: quote_call_transcriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quote_call_transcriptions_id_seq OWNED BY public.quote_call_transcriptions.id;


--
-- TOC entry 584 (class 1259 OID 94809)
-- Name: quote_calls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quote_calls (
    id bigint NOT NULL,
    account_id integer,
    campaign_id integer,
    call_sid character varying,
    status character varying,
    caller character varying,
    called character varying,
    direction character varying,
    shaken_stir_status character varying,
    call_duration integer,
    recording_url character varying,
    lead_type_id integer,
    charged boolean,
    price numeric(5,2),
    affiliate_id integer,
    call_rep character varying,
    refunded boolean,
    state character varying,
    lead_id integer,
    cost numeric(5,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    brand_id bigint,
    billable_duration integer,
    ad_group_id bigint,
    call_listing_id integer,
    price_to_charge numeric(10,2),
    transfer_type character varying,
    duplicate boolean DEFAULT false NOT NULL,
    pst_hour timestamp(6) without time zone,
    pst_day timestamp(6) without time zone,
    pst_week timestamp(6) without time zone,
    pst_month timestamp(6) without time zone,
    pst_quarter timestamp(6) without time zone,
    pst_year timestamp(6) without time zone,
    time_to_pickup numeric(6,2),
    aid character varying,
    cid character varying
);


ALTER TABLE public.quote_calls OWNER TO postgres;

--
-- TOC entry 585 (class 1259 OID 94816)
-- Name: quote_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quote_calls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quote_calls_id_seq OWNER TO postgres;

--
-- TOC entry 7819 (class 0 OID 0)
-- Dependencies: 585
-- Name: quote_calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quote_calls_id_seq OWNED BY public.quote_calls.id;


--
-- TOC entry 586 (class 1259 OID 94818)
-- Name: quote_form_visits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quote_form_visits (
    id bigint NOT NULL,
    ip character varying,
    user_agent text,
    prefill_query_id bigint,
    session_id character varying,
    started boolean,
    converted boolean,
    call boolean,
    lead_generated boolean,
    call_generated boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    visit_token character varying,
    visitor_token character varying,
    referrer text,
    referring_domain character varying,
    landing_page text,
    browser character varying,
    os character varying,
    device_type character varying,
    country character varying,
    region character varying,
    city character varying,
    latitude double precision,
    longitude double precision,
    utm_source character varying,
    utm_medium character varying,
    utm_term character varying,
    utm_content character varying,
    utm_campaign character varying,
    app_version character varying,
    os_version character varying,
    platform character varying,
    started_at timestamp(6) without time zone,
    jornaya_lead_id character varying,
    trusted_form_token character varying,
    step_id character varying,
    consent_certificate_id character varying,
    submit_clicked boolean DEFAULT false
);


ALTER TABLE public.quote_form_visits OWNER TO postgres;

--
-- TOC entry 587 (class 1259 OID 94825)
-- Name: quote_form_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quote_form_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quote_form_visits_id_seq OWNER TO postgres;

--
-- TOC entry 7820 (class 0 OID 0)
-- Dependencies: 587
-- Name: quote_form_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quote_form_visits_id_seq OWNED BY public.quote_form_visits.id;


--
-- TOC entry 588 (class 1259 OID 94827)
-- Name: quote_funnels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quote_funnels (
    id bigint NOT NULL,
    account_id bigint,
    lead_type_id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    active boolean,
    enable_email_validation boolean DEFAULT true,
    enable_phone_validation boolean DEFAULT true,
    form_header_tracking_code text,
    form_body_tracking_code text
);


ALTER TABLE public.quote_funnels OWNER TO postgres;

--
-- TOC entry 589 (class 1259 OID 94835)
-- Name: quote_funnels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quote_funnels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quote_funnels_id_seq OWNER TO postgres;

--
-- TOC entry 7821 (class 0 OID 0)
-- Dependencies: 589
-- Name: quote_funnels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quote_funnels_id_seq OWNED BY public.quote_funnels.id;


--
-- TOC entry 590 (class 1259 OID 94837)
-- Name: quote_funnels_prices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quote_funnels_prices (
    id bigint NOT NULL,
    price numeric,
    lead_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.quote_funnels_prices OWNER TO postgres;

--
-- TOC entry 591 (class 1259 OID 94843)
-- Name: quote_funnels_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quote_funnels_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quote_funnels_prices_id_seq OWNER TO postgres;

--
-- TOC entry 7822 (class 0 OID 0)
-- Dependencies: 591
-- Name: quote_funnels_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quote_funnels_prices_id_seq OWNED BY public.quote_funnels_prices.id;


--
-- TOC entry 592 (class 1259 OID 94845)
-- Name: rds_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rds_logs (
    id bigint NOT NULL,
    log_stream character varying NOT NULL,
    message text,
    message_id character varying,
    duration_ms numeric(20,2),
    "timestamp" timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jira_key character varying
);


ALTER TABLE public.rds_logs OWNER TO postgres;

--
-- TOC entry 593 (class 1259 OID 94852)
-- Name: rds_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rds_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rds_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7823 (class 0 OID 0)
-- Dependencies: 593
-- Name: rds_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rds_logs_id_seq OWNED BY public.rds_logs.id;


--
-- TOC entry 594 (class 1259 OID 94854)
-- Name: receipt_transaction_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.receipt_transaction_types (
    id bigint NOT NULL,
    name character varying DEFAULT 'null'::character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.receipt_transaction_types OWNER TO postgres;

--
-- TOC entry 595 (class 1259 OID 94861)
-- Name: receipt_transaction_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.receipt_transaction_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.receipt_transaction_types_id_seq OWNER TO postgres;

--
-- TOC entry 7824 (class 0 OID 0)
-- Dependencies: 595
-- Name: receipt_transaction_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.receipt_transaction_types_id_seq OWNED BY public.receipt_transaction_types.id;


--
-- TOC entry 596 (class 1259 OID 94863)
-- Name: receipt_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.receipt_types (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_debit boolean
);


ALTER TABLE public.receipt_types OWNER TO postgres;

--
-- TOC entry 597 (class 1259 OID 94869)
-- Name: receipt_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.receipt_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.receipt_types_id_seq OWNER TO postgres;

--
-- TOC entry 7825 (class 0 OID 0)
-- Dependencies: 597
-- Name: receipt_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.receipt_types_id_seq OWNED BY public.receipt_types.id;


--
-- TOC entry 598 (class 1259 OID 94871)
-- Name: receipts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.receipts (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    receipt_type_id bigint NOT NULL,
    user_id bigint NOT NULL,
    receipt_transaction_type_id bigint,
    debit numeric(12,2) DEFAULT 0.0,
    credit numeric(12,2) DEFAULT 0.0,
    current_balance numeric(12,2) DEFAULT 0.0,
    lead_id bigint,
    memo character varying,
    promo_balance numeric(12,2) DEFAULT 0.0,
    promo smallint DEFAULT 0,
    receipt_json text,
    discarded_at timestamp(6) without time zone,
    campaign_id bigint,
    brand_id bigint,
    invoice_id bigint,
    receipt_item_id bigint,
    admin_user_id bigint,
    ip_address character varying
);


ALTER TABLE public.receipts OWNER TO postgres;

--
-- TOC entry 599 (class 1259 OID 94882)
-- Name: receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.receipts_id_seq OWNER TO postgres;

--
-- TOC entry 7826 (class 0 OID 0)
-- Dependencies: 599
-- Name: receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.receipts_id_seq OWNED BY public.receipts.id;


--
-- TOC entry 600 (class 1259 OID 94884)
-- Name: recently_visited_client_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recently_visited_client_users (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    admin_user_id bigint
);


ALTER TABLE public.recently_visited_client_users OWNER TO postgres;

--
-- TOC entry 601 (class 1259 OID 94887)
-- Name: recently_visited_client_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recently_visited_client_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.recently_visited_client_users_id_seq OWNER TO postgres;

--
-- TOC entry 7827 (class 0 OID 0)
-- Dependencies: 601
-- Name: recently_visited_client_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.recently_visited_client_users_id_seq OWNED BY public.recently_visited_client_users.id;


--
-- TOC entry 602 (class 1259 OID 94889)
-- Name: registration_pending_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registration_pending_users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    company_name character varying,
    phone_num character varying,
    timezone character varying,
    address character varying,
    city character varying,
    state character varying,
    zip_code bigint,
    insurance_carrier_id bigint,
    discarded_at timestamp(6) without time zone,
    user_id bigint,
    invoice smallint DEFAULT 0,
    sales_manager_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    uuid character varying
);


ALTER TABLE public.registration_pending_users OWNER TO postgres;

--
-- TOC entry 603 (class 1259 OID 94897)
-- Name: registration_pending_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.registration_pending_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.registration_pending_users_id_seq OWNER TO postgres;

--
-- TOC entry 7828 (class 0 OID 0)
-- Dependencies: 603
-- Name: registration_pending_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.registration_pending_users_id_seq OWNED BY public.registration_pending_users.id;


--
-- TOC entry 604 (class 1259 OID 94899)
-- Name: response_parser_functions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.response_parser_functions (
    id bigint NOT NULL,
    fn_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.response_parser_functions OWNER TO postgres;

--
-- TOC entry 605 (class 1259 OID 94905)
-- Name: response_parser_functions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.response_parser_functions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.response_parser_functions_id_seq OWNER TO postgres;

--
-- TOC entry 7829 (class 0 OID 0)
-- Dependencies: 605
-- Name: response_parser_functions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.response_parser_functions_id_seq OWNED BY public.response_parser_functions.id;


--
-- TOC entry 606 (class 1259 OID 94907)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    account_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 607 (class 1259 OID 94913)
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO postgres;

--
-- TOC entry 7830 (class 0 OID 0)
-- Dependencies: 607
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- TOC entry 608 (class 1259 OID 94915)
-- Name: rtb_bids; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rtb_bids (
    id bigint NOT NULL,
    click_ping_id integer,
    recommended_bid numeric(5,2),
    output_code character varying,
    response_text text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    latency integer,
    timeout boolean,
    revenue_exp numeric(6,2),
    clickthrough_exp numeric(6,2),
    bid_to_use numeric(7,2),
    cm numeric(7,2)
);


ALTER TABLE public.rtb_bids OWNER TO postgres;

--
-- TOC entry 609 (class 1259 OID 94921)
-- Name: rtb_bids_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rtb_bids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rtb_bids_id_seq OWNER TO postgres;

--
-- TOC entry 7831 (class 0 OID 0)
-- Dependencies: 609
-- Name: rtb_bids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rtb_bids_id_seq OWNED BY public.rtb_bids.id;


--
-- TOC entry 610 (class 1259 OID 94923)
-- Name: rule_validator_checks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rule_validator_checks (
    id bigint NOT NULL,
    rule_name character varying NOT NULL,
    rule_desc character varying,
    product_name character varying NOT NULL,
    status character varying DEFAULT 'failed'::character varying NOT NULL,
    logs text,
    "timestamp" timestamp(6) without time zone NOT NULL,
    account_id bigint,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jira_key character varying,
    error_logs text
);


ALTER TABLE public.rule_validator_checks OWNER TO postgres;

--
-- TOC entry 611 (class 1259 OID 94931)
-- Name: rule_validator_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rule_validator_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rule_validator_checks_id_seq OWNER TO postgres;

--
-- TOC entry 7832 (class 0 OID 0)
-- Dependencies: 611
-- Name: rule_validator_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rule_validator_checks_id_seq OWNED BY public.rule_validator_checks.id;


--
-- TOC entry 612 (class 1259 OID 94933)
-- Name: sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sales (
    year integer,
    month integer,
    qty integer
);


ALTER TABLE public.sales OWNER TO postgres;

--
-- TOC entry 613 (class 1259 OID 94936)
-- Name: sample_leads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sample_leads (
    id bigint NOT NULL,
    data text,
    lead_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.sample_leads OWNER TO postgres;

--
-- TOC entry 614 (class 1259 OID 94942)
-- Name: sample_leads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sample_leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sample_leads_id_seq OWNER TO postgres;

--
-- TOC entry 7833 (class 0 OID 0)
-- Dependencies: 614
-- Name: sample_leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sample_leads_id_seq OWNED BY public.sample_leads.id;


--
-- TOC entry 615 (class 1259 OID 94944)
-- Name: scheduled_report_emails; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_report_emails (
    id bigint NOT NULL,
    title character varying,
    subject text,
    description text,
    recipients jsonb,
    report_format character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    scheduled_report_id bigint
);


ALTER TABLE public.scheduled_report_emails OWNER TO postgres;

--
-- TOC entry 616 (class 1259 OID 94950)
-- Name: scheduled_report_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scheduled_report_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scheduled_report_emails_id_seq OWNER TO postgres;

--
-- TOC entry 7834 (class 0 OID 0)
-- Dependencies: 616
-- Name: scheduled_report_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scheduled_report_emails_id_seq OWNED BY public.scheduled_report_emails.id;


--
-- TOC entry 617 (class 1259 OID 94952)
-- Name: scheduled_report_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_report_logs (
    id bigint NOT NULL,
    scheduled_report_id bigint NOT NULL,
    log_level text NOT NULL,
    log_entry text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_entry_bt text,
    account_id bigint,
    user_id bigint,
    scheduled_report_upload_id bigint
);


ALTER TABLE public.scheduled_report_logs OWNER TO postgres;

--
-- TOC entry 618 (class 1259 OID 94958)
-- Name: scheduled_report_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scheduled_report_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scheduled_report_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7835 (class 0 OID 0)
-- Dependencies: 618
-- Name: scheduled_report_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scheduled_report_logs_id_seq OWNED BY public.scheduled_report_logs.id;


--
-- TOC entry 619 (class 1259 OID 94960)
-- Name: scheduled_report_sftps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_report_sftps (
    id bigint NOT NULL,
    file_name character varying,
    create_trigger_file boolean,
    host character varying,
    port integer,
    path character varying,
    username character varying,
    is_key_login_type boolean,
    password character varying,
    key text,
    report_format character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    scheduled_report_id bigint
);


ALTER TABLE public.scheduled_report_sftps OWNER TO postgres;

--
-- TOC entry 620 (class 1259 OID 94966)
-- Name: scheduled_report_sftps_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scheduled_report_sftps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scheduled_report_sftps_id_seq OWNER TO postgres;

--
-- TOC entry 7836 (class 0 OID 0)
-- Dependencies: 620
-- Name: scheduled_report_sftps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scheduled_report_sftps_id_seq OWNED BY public.scheduled_report_sftps.id;


--
-- TOC entry 621 (class 1259 OID 94968)
-- Name: scheduled_report_uploads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_report_uploads (
    id bigint NOT NULL,
    scheduled_report_id bigint NOT NULL,
    file character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    token character varying
);


ALTER TABLE public.scheduled_report_uploads OWNER TO postgres;

--
-- TOC entry 622 (class 1259 OID 94974)
-- Name: scheduled_report_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scheduled_report_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scheduled_report_uploads_id_seq OWNER TO postgres;

--
-- TOC entry 7837 (class 0 OID 0)
-- Dependencies: 622
-- Name: scheduled_report_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scheduled_report_uploads_id_seq OWNED BY public.scheduled_report_uploads.id;


--
-- TOC entry 623 (class 1259 OID 94976)
-- Name: scheduled_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_reports (
    id bigint NOT NULL,
    active boolean DEFAULT false NOT NULL,
    delivery_method character varying,
    user_smart_view_id bigint NOT NULL,
    cron_string character varying,
    current_trigger_count integer,
    total_trigger_count integer,
    send_immediately boolean,
    metadata jsonb,
    last_sent_at timestamp(6) without time zone,
    last_error_at timestamp(6) without time zone,
    last_attempt_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    account_id bigint NOT NULL,
    last_error text
);


ALTER TABLE public.scheduled_reports OWNER TO postgres;

--
-- TOC entry 624 (class 1259 OID 94983)
-- Name: scheduled_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scheduled_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scheduled_reports_id_seq OWNER TO postgres;

--
-- TOC entry 7838 (class 0 OID 0)
-- Dependencies: 624
-- Name: scheduled_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scheduled_reports_id_seq OWNED BY public.scheduled_reports.id;


--
-- TOC entry 625 (class 1259 OID 94985)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- TOC entry 626 (class 1259 OID 94991)
-- Name: semaphore_deployments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.semaphore_deployments (
    id bigint NOT NULL,
    state character varying,
    result text,
    name character varying,
    error_description character varying,
    user_name character varying,
    pull_request character varying,
    commit_sha character varying,
    environment character varying,
    "timestamp" timestamp(6) without time zone,
    jira_key character varying,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.semaphore_deployments OWNER TO postgres;

--
-- TOC entry 627 (class 1259 OID 94998)
-- Name: semaphore_deployments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.semaphore_deployments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.semaphore_deployments_id_seq OWNER TO postgres;

--
-- TOC entry 7839 (class 0 OID 0)
-- Dependencies: 627
-- Name: semaphore_deployments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.semaphore_deployments_id_seq OWNED BY public.semaphore_deployments.id;


--
-- TOC entry 628 (class 1259 OID 95000)
-- Name: sf_filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sf_filters (
    id bigint NOT NULL,
    name character varying,
    filter_description text,
    filter_type character varying,
    active boolean DEFAULT false,
    price numeric(5,2),
    field_values character varying,
    query_param character varying,
    lead_type_id bigint NOT NULL,
    product_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_an_ad_group_level_filter boolean DEFAULT false NOT NULL,
    is_a_campaign_level_filter boolean DEFAULT false NOT NULL,
    internal boolean DEFAULT false,
    is_a_currency boolean DEFAULT false,
    retail boolean DEFAULT true,
    discarded_at timestamp(6) without time zone,
    admin_only boolean DEFAULT false
);


ALTER TABLE public.sf_filters OWNER TO postgres;

--
-- TOC entry 629 (class 1259 OID 95013)
-- Name: sf_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sf_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sf_filters_id_seq OWNER TO postgres;

--
-- TOC entry 7840 (class 0 OID 0)
-- Dependencies: 629
-- Name: sf_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sf_filters_id_seq OWNED BY public.sf_filters.id;


--
-- TOC entry 630 (class 1259 OID 95015)
-- Name: sf_lead_integration_macro_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sf_lead_integration_macro_categories (
    id bigint NOT NULL,
    name character varying,
    parent_category_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.sf_lead_integration_macro_categories OWNER TO postgres;

--
-- TOC entry 631 (class 1259 OID 95021)
-- Name: sf_lead_integration_macro_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sf_lead_integration_macro_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sf_lead_integration_macro_categories_id_seq OWNER TO postgres;

--
-- TOC entry 7841 (class 0 OID 0)
-- Dependencies: 631
-- Name: sf_lead_integration_macro_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sf_lead_integration_macro_categories_id_seq OWNED BY public.sf_lead_integration_macro_categories.id;


--
-- TOC entry 632 (class 1259 OID 95023)
-- Name: sf_lead_integration_macro_lead_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sf_lead_integration_macro_lead_types (
    id bigint NOT NULL,
    sf_lead_integration_macro_id bigint NOT NULL,
    lead_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.sf_lead_integration_macro_lead_types OWNER TO postgres;

--
-- TOC entry 633 (class 1259 OID 95026)
-- Name: sf_lead_integration_macro_lead_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sf_lead_integration_macro_lead_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sf_lead_integration_macro_lead_types_id_seq OWNER TO postgres;

--
-- TOC entry 7842 (class 0 OID 0)
-- Dependencies: 633
-- Name: sf_lead_integration_macro_lead_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sf_lead_integration_macro_lead_types_id_seq OWNED BY public.sf_lead_integration_macro_lead_types.id;


--
-- TOC entry 634 (class 1259 OID 95028)
-- Name: sf_lead_integration_macros; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sf_lead_integration_macros (
    id bigint NOT NULL,
    active boolean,
    key character varying,
    display_key character varying,
    is_enum boolean,
    enums text[] DEFAULT '{}'::text[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    parent_macro_id bigint,
    has_sub_macros boolean,
    is_common boolean DEFAULT false,
    sf_lead_integration_macro_category_id integer
);


ALTER TABLE public.sf_lead_integration_macros OWNER TO postgres;

--
-- TOC entry 635 (class 1259 OID 95036)
-- Name: sf_lead_integration_macros_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sf_lead_integration_macros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sf_lead_integration_macros_id_seq OWNER TO postgres;

--
-- TOC entry 7843 (class 0 OID 0)
-- Dependencies: 635
-- Name: sf_lead_integration_macros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sf_lead_integration_macros_id_seq OWNED BY public.sf_lead_integration_macros.id;


--
-- TOC entry 636 (class 1259 OID 95038)
-- Name: sf_smart_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sf_smart_views (
    id bigint NOT NULL,
    name character varying,
    smart_view_filters jsonb,
    smart_view_group_bys jsonb,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    individual_clicks boolean DEFAULT false,
    individual_calls boolean DEFAULT false,
    product_type_id bigint NOT NULL,
    individual_leads boolean DEFAULT false,
    config jsonb
);


ALTER TABLE public.sf_smart_views OWNER TO postgres;

--
-- TOC entry 637 (class 1259 OID 95047)
-- Name: sf_smart_views_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sf_smart_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sf_smart_views_id_seq OWNER TO postgres;

--
-- TOC entry 7844 (class 0 OID 0)
-- Dependencies: 637
-- Name: sf_smart_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sf_smart_views_id_seq OWNED BY public.sf_smart_views.id;


--
-- TOC entry 638 (class 1259 OID 95049)
-- Name: sidekiq_job_error_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sidekiq_job_error_logs (
    id bigint NOT NULL,
    log text,
    log_bt text,
    args jsonb,
    source_id bigint,
    job_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.sidekiq_job_error_logs OWNER TO postgres;

--
-- TOC entry 639 (class 1259 OID 95055)
-- Name: sidekiq_job_error_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sidekiq_job_error_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sidekiq_job_error_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7845 (class 0 OID 0)
-- Dependencies: 639
-- Name: sidekiq_job_error_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sidekiq_job_error_logs_id_seq OWNED BY public.sidekiq_job_error_logs.id;


--
-- TOC entry 640 (class 1259 OID 95057)
-- Name: slack_support_channel_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.slack_support_channel_requests (
    id bigint NOT NULL,
    title character varying,
    status character varying,
    description text,
    reported_at timestamp(6) without time zone,
    admin_user_id bigint,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.slack_support_channel_requests OWNER TO postgres;

--
-- TOC entry 641 (class 1259 OID 95063)
-- Name: slack_support_channel_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.slack_support_channel_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.slack_support_channel_requests_id_seq OWNER TO postgres;

--
-- TOC entry 7846 (class 0 OID 0)
-- Dependencies: 641
-- Name: slack_support_channel_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.slack_support_channel_requests_id_seq OWNED BY public.slack_support_channel_requests.id;


--
-- TOC entry 642 (class 1259 OID 95065)
-- Name: slow_query_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.slow_query_logs (
    id bigint NOT NULL,
    duration_ms numeric(20,2),
    connection character varying,
    sql text,
    binds text,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    connection_role character varying
);


ALTER TABLE public.slow_query_logs OWNER TO postgres;

--
-- TOC entry 643 (class 1259 OID 95072)
-- Name: slow_query_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.slow_query_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.slow_query_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7847 (class 0 OID 0)
-- Dependencies: 643
-- Name: slow_query_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.slow_query_logs_id_seq OWNED BY public.slow_query_logs.id;


--
-- TOC entry 644 (class 1259 OID 95074)
-- Name: source_pixel_columns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.source_pixel_columns (
    id bigint NOT NULL,
    click_conversion_pixel_id bigint NOT NULL,
    disp_count boolean,
    disp_cvr boolean,
    disp_cpa boolean,
    disp_rev boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    disp_calls_count boolean DEFAULT true,
    disp_calls_cpa boolean DEFAULT true,
    disp_calls_cvr boolean DEFAULT true,
    disp_calls_rev boolean DEFAULT true,
    disp_leads_count boolean DEFAULT true,
    disp_leads_cpa boolean DEFAULT true,
    disp_leads_cvr boolean DEFAULT true,
    disp_leads_rev boolean DEFAULT true
);


ALTER TABLE public.source_pixel_columns OWNER TO postgres;

--
-- TOC entry 645 (class 1259 OID 95085)
-- Name: source_pixel_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.source_pixel_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.source_pixel_columns_id_seq OWNER TO postgres;

--
-- TOC entry 7848 (class 0 OID 0)
-- Dependencies: 645
-- Name: source_pixel_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.source_pixel_columns_id_seq OWNED BY public.source_pixel_columns.id;


--
-- TOC entry 646 (class 1259 OID 95087)
-- Name: source_setting_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.source_setting_notes (
    id bigint NOT NULL,
    text text,
    admin_user_id bigint NOT NULL,
    campaign_source_setting_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.source_setting_notes OWNER TO postgres;

--
-- TOC entry 647 (class 1259 OID 95093)
-- Name: source_setting_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.source_setting_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.source_setting_notes_id_seq OWNER TO postgres;

--
-- TOC entry 7849 (class 0 OID 0)
-- Dependencies: 647
-- Name: source_setting_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.source_setting_notes_id_seq OWNED BY public.source_setting_notes.id;


--
-- TOC entry 648 (class 1259 OID 95095)
-- Name: source_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.source_types (
    id bigint NOT NULL,
    name character varying,
    description text,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    internal boolean DEFAULT true NOT NULL,
    project_id character varying,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.source_types OWNER TO postgres;

--
-- TOC entry 649 (class 1259 OID 95103)
-- Name: source_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.source_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.source_types_id_seq OWNER TO postgres;

--
-- TOC entry 7850 (class 0 OID 0)
-- Dependencies: 649
-- Name: source_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.source_types_id_seq OWNED BY public.source_types.id;


--
-- TOC entry 650 (class 1259 OID 95105)
-- Name: state_names; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.state_names (
    id bigint NOT NULL,
    state_code character varying,
    state_full_name character varying
);


ALTER TABLE public.state_names OWNER TO postgres;

--
-- TOC entry 651 (class 1259 OID 95111)
-- Name: state_names_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.state_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.state_names_id_seq OWNER TO postgres;

--
-- TOC entry 7851 (class 0 OID 0)
-- Dependencies: 651
-- Name: state_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.state_names_id_seq OWNED BY public.state_names.id;


--
-- TOC entry 652 (class 1259 OID 95113)
-- Name: syndi_click_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.syndi_click_rules (
    id bigint NOT NULL,
    campaign_id integer,
    network_id integer,
    advertiser character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    margin numeric(5,2),
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.syndi_click_rules OWNER TO postgres;

--
-- TOC entry 653 (class 1259 OID 95119)
-- Name: syndi_click_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.syndi_click_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.syndi_click_rules_id_seq OWNER TO postgres;

--
-- TOC entry 7852 (class 0 OID 0)
-- Dependencies: 653
-- Name: syndi_click_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.syndi_click_rules_id_seq OWNED BY public.syndi_click_rules.id;


--
-- TOC entry 654 (class 1259 OID 95121)
-- Name: syndi_click_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.syndi_click_settings (
    id bigint NOT NULL,
    campaign_id bigint,
    status boolean,
    token_id character varying,
    margin numeric DEFAULT 50.0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lead_type_id bigint,
    discarded_at timestamp(6) without time zone,
    brand_id integer
);


ALTER TABLE public.syndi_click_settings OWNER TO postgres;

--
-- TOC entry 655 (class 1259 OID 95128)
-- Name: syndi_click_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.syndi_click_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.syndi_click_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7853 (class 0 OID 0)
-- Dependencies: 655
-- Name: syndi_click_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.syndi_click_settings_id_seq OWNED BY public.syndi_click_settings.id;


--
-- TOC entry 656 (class 1259 OID 95130)
-- Name: template_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.template_assignments (
    id bigint NOT NULL,
    admin_role_id bigint NOT NULL,
    admin_notification_template_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.template_assignments OWNER TO postgres;

--
-- TOC entry 657 (class 1259 OID 95133)
-- Name: template_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.template_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.template_assignments_id_seq OWNER TO postgres;

--
-- TOC entry 7854 (class 0 OID 0)
-- Dependencies: 657
-- Name: template_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.template_assignments_id_seq OWNED BY public.template_assignments.id;


--
-- TOC entry 658 (class 1259 OID 95135)
-- Name: terms_of_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.terms_of_services (
    id bigint NOT NULL,
    name character varying,
    url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description character varying,
    updated_by integer
);


ALTER TABLE public.terms_of_services OWNER TO postgres;

--
-- TOC entry 659 (class 1259 OID 95141)
-- Name: terms_of_services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.terms_of_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.terms_of_services_id_seq OWNER TO postgres;

--
-- TOC entry 7855 (class 0 OID 0)
-- Dependencies: 659
-- Name: terms_of_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.terms_of_services_id_seq OWNED BY public.terms_of_services.id;


--
-- TOC entry 660 (class 1259 OID 95143)
-- Name: trusted_form_certificates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trusted_form_certificates (
    id bigint NOT NULL,
    lead_id integer,
    token character varying,
    claim_id character varying,
    claimed_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone,
    masked_cert_url character varying,
    share_url text,
    snapshot_url character varying,
    page_id character varying,
    age character varying,
    event_duration character varying,
    operating_system character varying,
    browser character varying,
    user_agent character varying,
    ip character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.trusted_form_certificates OWNER TO postgres;

--
-- TOC entry 661 (class 1259 OID 95149)
-- Name: trusted_form_certificates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trusted_form_certificates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trusted_form_certificates_id_seq OWNER TO postgres;

--
-- TOC entry 7856 (class 0 OID 0)
-- Dependencies: 661
-- Name: trusted_form_certificates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trusted_form_certificates_id_seq OWNED BY public.trusted_form_certificates.id;


--
-- TOC entry 662 (class 1259 OID 95151)
-- Name: twilio_phone_numbers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.twilio_phone_numbers (
    id bigint NOT NULL,
    phone_number character varying,
    campaign_id integer,
    account_id integer,
    friendly_name character varying,
    voice_url character varying,
    voice_fallback_url character varying,
    sms_url character varying,
    sms_fallback_url character varying,
    active boolean DEFAULT true,
    sid character varying,
    released_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.twilio_phone_numbers OWNER TO postgres;

--
-- TOC entry 663 (class 1259 OID 95158)
-- Name: twilio_phone_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.twilio_phone_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.twilio_phone_numbers_id_seq OWNER TO postgres;

--
-- TOC entry 7857 (class 0 OID 0)
-- Dependencies: 663
-- Name: twilio_phone_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.twilio_phone_numbers_id_seq OWNED BY public.twilio_phone_numbers.id;


--
-- TOC entry 664 (class 1259 OID 95160)
-- Name: user_activity_customize_columns_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_activity_customize_columns_orders (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    visit_token integer DEFAULT 0,
    visitor_token integer DEFAULT 0,
    user_id integer DEFAULT 0,
    ip integer DEFAULT 0,
    user_agent integer DEFAULT 0,
    referrer integer DEFAULT 0,
    referring_domain integer DEFAULT 0,
    landing_page integer DEFAULT 0,
    browser integer DEFAULT 0,
    os integer DEFAULT 0,
    device_type integer DEFAULT 0,
    country integer DEFAULT 0,
    region integer DEFAULT 0,
    city integer DEFAULT 0,
    latitude integer DEFAULT 0,
    longitude integer DEFAULT 0,
    utm_source integer DEFAULT 0,
    utm_medium integer DEFAULT 0,
    utm_term integer DEFAULT 0,
    utm_content integer DEFAULT 0,
    utm_campaign integer DEFAULT 0,
    app_version integer DEFAULT 0,
    os_version integer DEFAULT 0,
    platform integer DEFAULT 0,
    started_at integer DEFAULT 0,
    company_name integer DEFAULT 0,
    account_id integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_activity_customize_columns_orders OWNER TO postgres;

--
-- TOC entry 665 (class 1259 OID 95190)
-- Name: user_activity_customize_columns_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_activity_customize_columns_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_activity_customize_columns_orders_id_seq OWNER TO postgres;

--
-- TOC entry 7858 (class 0 OID 0)
-- Dependencies: 665
-- Name: user_activity_customize_columns_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_activity_customize_columns_orders_id_seq OWNED BY public.user_activity_customize_columns_orders.id;


--
-- TOC entry 666 (class 1259 OID 95192)
-- Name: user_col_pref_admin_dashboards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_admin_dashboards (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    is_inventory boolean DEFAULT false,
    is_opportunities boolean DEFAULT false,
    is_target_rate boolean DEFAULT false,
    is_searches boolean DEFAULT false,
    is_bid_rate boolean DEFAULT false,
    is_bids_won boolean DEFAULT false,
    is_epw boolean DEFAULT false,
    is_win_rate boolean DEFAULT false,
    is_accepted boolean DEFAULT false,
    is_success_rate boolean DEFAULT false,
    is_avg_bid boolean DEFAULT false,
    is_avg_cpl boolean DEFAULT false,
    is_spend boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_conversions boolean DEFAULT false,
    is_cvr boolean DEFAULT false,
    is_cpa boolean DEFAULT false,
    is_rpc boolean DEFAULT false,
    is_profit boolean DEFAULT false,
    is_cm boolean DEFAULT false,
    is_gp_per boolean DEFAULT false,
    is_cost boolean DEFAULT false,
    is_leads_generated boolean DEFAULT false,
    is_calls_generated boolean DEFAULT false
);


ALTER TABLE public.user_col_pref_admin_dashboards OWNER TO postgres;

--
-- TOC entry 667 (class 1259 OID 95218)
-- Name: user_col_pref_admin_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_admin_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_admin_dashboards_id_seq OWNER TO postgres;

--
-- TOC entry 7859 (class 0 OID 0)
-- Dependencies: 667
-- Name: user_col_pref_admin_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_admin_dashboards_id_seq OWNED BY public.user_col_pref_admin_dashboards.id;


--
-- TOC entry 668 (class 1259 OID 95220)
-- Name: user_col_pref_analytics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_analytics (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    is_lead_searches boolean DEFAULT false,
    is_lead_selected boolean DEFAULT false,
    is_lead_won boolean DEFAULT false,
    is_lead_total_leads boolean DEFAULT false,
    is_lead_cost boolean DEFAULT false,
    is_lead_avg_cpl boolean DEFAULT false,
    is_lead_avg_bid boolean DEFAULT false,
    is_call_total_calls boolean DEFAULT false,
    is_call_billable_calls boolean DEFAULT false,
    is_call_cost boolean DEFAULT false,
    is_call_avg_cpc boolean DEFAULT false,
    is_call_total_duration boolean DEFAULT false,
    is_call_avg_duration boolean DEFAULT false,
    is_click_searches boolean DEFAULT false,
    is_click_impressions boolean DEFAULT false,
    is_click_total_clicks boolean DEFAULT false,
    is_click_ctr boolean DEFAULT false,
    is_click_cost boolean DEFAULT false,
    is_click_avg_cpc boolean DEFAULT false,
    is_click_avg_bid boolean DEFAULT false,
    is_click_avg_pos boolean DEFAULT false,
    is_individual_clicks_brand_name boolean DEFAULT false,
    is_individual_clicks_click_id boolean DEFAULT false,
    is_individual_clicks_campaign boolean DEFAULT false,
    is_individual_clicks_ad_group boolean DEFAULT false,
    is_individual_clicks_creative boolean DEFAULT false,
    is_individual_clicks_pub_aid boolean DEFAULT false,
    is_individual_clicks_pub_cid boolean DEFAULT false,
    is_individual_clicks_first_name boolean DEFAULT false,
    is_individual_clicks_last_name boolean DEFAULT false,
    is_individual_clicks_phone boolean DEFAULT false,
    is_individual_clicks_email boolean DEFAULT false,
    is_individual_clicks_zip boolean DEFAULT false,
    is_individual_clicks_city boolean DEFAULT false,
    is_individual_clicks_county boolean DEFAULT false,
    is_individual_clicks_ip_address boolean DEFAULT false,
    is_individual_clicks_device_type boolean DEFAULT false,
    is_individual_clicks_source_type_name boolean DEFAULT false,
    is_individual_clicks_cost boolean DEFAULT false,
    is_individual_clicks_position boolean DEFAULT false,
    is_individual_clicks_timestamp boolean DEFAULT false,
    is_individual_calls_brand_name boolean DEFAULT false,
    is_individual_calls_timestamp boolean DEFAULT false,
    is_individual_calls_campaign boolean DEFAULT false,
    is_individual_calls_profile boolean DEFAULT false,
    is_individual_calls_call_type boolean DEFAULT false,
    is_individual_calls_phone boolean DEFAULT false,
    is_individual_calls_state boolean DEFAULT false,
    is_individual_calls_zip boolean DEFAULT false,
    is_individual_calls_call_duration boolean DEFAULT false,
    is_individual_calls_source_type boolean DEFAULT false,
    is_individual_calls_cost boolean DEFAULT false,
    is_individual_calls_insured boolean DEFAULT false,
    is_individual_calls_home_owner boolean DEFAULT false,
    is_individual_calls_num_vehicles boolean DEFAULT false,
    is_individual_calls_jornaya_lead_id boolean DEFAULT false,
    is_individual_calls_trusted_form_token boolean DEFAULT false,
    profit boolean DEFAULT false,
    contribution_margin boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_individual_clicks_admin_consumer_age boolean DEFAULT false,
    is_individual_clicks_admin_bankruptcy boolean DEFAULT false,
    is_individual_clicks_admin_credit boolean DEFAULT false,
    is_individual_clicks_admin_education boolean DEFAULT false,
    is_individual_clicks_admin_gender boolean DEFAULT false,
    is_individual_clicks_admin_home_owner boolean DEFAULT false,
    is_individual_clicks_admin_license_active boolean DEFAULT false,
    is_individual_clicks_admin_married boolean DEFAULT false,
    is_individual_clicks_admin_num_drivers boolean DEFAULT false,
    is_individual_clicks_admin_occupation boolean DEFAULT false,
    is_individual_clicks_admin_years_licensed boolean DEFAULT false,
    is_individual_clicks_admin_annual_mileage boolean DEFAULT false,
    is_individual_clicks_admin_leased boolean DEFAULT false,
    is_individual_clicks_admin_num_vehicles boolean DEFAULT false,
    is_individual_clicks_admin_primary_use boolean DEFAULT false,
    is_individual_clicks_admin_coll_deductible boolean DEFAULT false,
    is_individual_clicks_admin_comp_deductible boolean DEFAULT false,
    is_individual_clicks_admin_continuous_coverage boolean DEFAULT false,
    is_individual_clicks_admin_coverage boolean DEFAULT false,
    is_individual_clicks_admin_insured boolean DEFAULT false,
    is_individual_clicks_admin_current_insurer boolean DEFAULT false,
    is_individual_clicks_admin_sr22_required boolean DEFAULT false,
    is_individual_clicks_admin_accidents boolean DEFAULT false,
    is_individual_clicks_admin_accidents_at_fault boolean DEFAULT false,
    is_individual_clicks_admin_duis boolean DEFAULT false,
    is_individual_clicks_admin_tickets boolean DEFAULT false,
    is_individual_clicks_admin_all_incidents boolean DEFAULT false,
    is_individual_leads_brand_name boolean DEFAULT false,
    is_individual_leads_click_id boolean DEFAULT false,
    is_individual_leads_campaign boolean DEFAULT false,
    is_individual_leads_ad_group boolean DEFAULT false,
    is_individual_leads_pub_aid boolean DEFAULT false,
    is_individual_leads_pub_cid boolean DEFAULT false,
    is_individual_leads_first_name boolean DEFAULT false,
    is_individual_leads_last_name boolean DEFAULT false,
    is_individual_leads_phone boolean DEFAULT false,
    is_individual_leads_email boolean DEFAULT false,
    is_individual_leads_zip boolean DEFAULT false,
    is_individual_leads_city boolean DEFAULT false,
    is_individual_leads_county boolean DEFAULT false,
    is_individual_leads_ip_address boolean DEFAULT false,
    is_individual_leads_device_type boolean DEFAULT false,
    is_individual_leads_source_type_name boolean DEFAULT false,
    is_individual_leads_cost boolean DEFAULT false,
    is_individual_leads_position boolean DEFAULT false,
    is_individual_leads_timestamp boolean DEFAULT false,
    is_click_total_leads boolean DEFAULT false,
    is_click_total_calls boolean DEFAULT false,
    is_individual_calls_consumer_phone boolean DEFAULT false,
    is_individual_leads_admin_consumer_age boolean DEFAULT false,
    is_individual_leads_admin_bankruptcy boolean DEFAULT false,
    is_individual_leads_admin_credit boolean DEFAULT false,
    is_individual_leads_admin_education boolean DEFAULT false,
    is_individual_leads_admin_gender boolean DEFAULT false,
    is_individual_leads_admin_home_owner boolean DEFAULT false,
    is_individual_leads_admin_license_active boolean DEFAULT false,
    is_individual_leads_admin_married boolean DEFAULT false,
    is_individual_leads_admin_num_drivers boolean DEFAULT false,
    is_individual_leads_admin_occupation boolean DEFAULT false,
    is_individual_leads_admin_years_licensed boolean DEFAULT false,
    is_individual_leads_admin_annual_mileage boolean DEFAULT false,
    is_individual_leads_admin_leased boolean DEFAULT false,
    is_individual_leads_admin_num_vehicles boolean DEFAULT false,
    is_individual_leads_admin_primary_use boolean DEFAULT false,
    is_individual_leads_admin_coll_deductible boolean DEFAULT false,
    is_individual_leads_admin_comp_deductible boolean DEFAULT false,
    is_individual_leads_admin_continuous_coverage boolean DEFAULT false,
    is_individual_leads_admin_coverage boolean DEFAULT false,
    is_individual_leads_admin_insured boolean DEFAULT false,
    is_individual_leads_admin_current_insurer boolean DEFAULT false,
    is_individual_leads_admin_sr22_required boolean DEFAULT false,
    is_individual_leads_admin_accidents boolean DEFAULT false,
    is_individual_leads_admin_accidents_at_fault boolean DEFAULT false,
    is_individual_leads_admin_duis boolean DEFAULT false,
    is_individual_leads_admin_tickets boolean DEFAULT false,
    is_individual_leads_admin_all_incidents boolean DEFAULT false,
    is_individual_calls_city boolean DEFAULT false,
    is_individual_calls_consumer_age boolean DEFAULT false,
    is_individual_calls_credit boolean DEFAULT false,
    is_individual_calls_education boolean DEFAULT false,
    is_individual_calls_gender boolean DEFAULT false,
    is_individual_calls_license_active boolean DEFAULT false,
    is_individual_calls_married boolean DEFAULT false,
    is_individual_calls_num_drivers boolean DEFAULT false,
    is_individual_calls_continuous_coverage boolean DEFAULT false,
    is_individual_leads_jornaya_lead_id boolean DEFAULT false,
    is_individual_clicks_bid boolean DEFAULT false,
    is_individual_calls_pub_aid boolean DEFAULT false,
    is_individual_clicks_viewed boolean DEFAULT false,
    is_individual_calls_transfer_number boolean DEFAULT false
);


ALTER TABLE public.user_col_pref_analytics OWNER TO postgres;

--
-- TOC entry 669 (class 1259 OID 95372)
-- Name: user_col_pref_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_analytics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_analytics_id_seq OWNER TO postgres;

--
-- TOC entry 7860 (class 0 OID 0)
-- Dependencies: 669
-- Name: user_col_pref_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_analytics_id_seq OWNED BY public.user_col_pref_analytics.id;


--
-- TOC entry 670 (class 1259 OID 95374)
-- Name: user_col_pref_calls_dashboard_campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_calls_dashboard_campaigns (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    opportunities boolean DEFAULT false,
    searches boolean DEFAULT false,
    total_calls boolean DEFAULT false,
    billable_calls boolean DEFAULT false,
    total_cost boolean DEFAULT false,
    avg_cpc boolean DEFAULT false,
    total_call_duration boolean DEFAULT false,
    avg_call_duration boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_col_pref_calls_dashboard_campaigns OWNER TO postgres;

--
-- TOC entry 671 (class 1259 OID 95385)
-- Name: user_col_pref_calls_dashboard_campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_calls_dashboard_campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_calls_dashboard_campaigns_id_seq OWNER TO postgres;

--
-- TOC entry 7861 (class 0 OID 0)
-- Dependencies: 671
-- Name: user_col_pref_calls_dashboard_campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_calls_dashboard_campaigns_id_seq OWNED BY public.user_col_pref_calls_dashboard_campaigns.id;


--
-- TOC entry 672 (class 1259 OID 95387)
-- Name: user_col_pref_calls_dashboard_states; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_calls_dashboard_states (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    opportunities boolean DEFAULT false,
    searches boolean DEFAULT false,
    total_calls boolean DEFAULT false,
    billable_calls boolean DEFAULT false,
    total_cost boolean DEFAULT false,
    avg_cpc boolean DEFAULT false,
    total_call_duration boolean DEFAULT false,
    avg_call_duration boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    insurance_type_opportunities boolean DEFAULT false,
    insurance_type_searches boolean DEFAULT false,
    insurance_type_total_calls boolean DEFAULT false,
    insurance_type_billable_calls boolean DEFAULT false,
    insurance_type_total_cost boolean DEFAULT false,
    insurance_type_avg_cpc boolean DEFAULT false,
    insurance_type_total_call_duration boolean DEFAULT false,
    insurance_type_avg_call_duration boolean DEFAULT false
);


ALTER TABLE public.user_col_pref_calls_dashboard_states OWNER TO postgres;

--
-- TOC entry 673 (class 1259 OID 95406)
-- Name: user_col_pref_calls_dashboard_states_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_calls_dashboard_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_calls_dashboard_states_id_seq OWNER TO postgres;

--
-- TOC entry 7862 (class 0 OID 0)
-- Dependencies: 673
-- Name: user_col_pref_calls_dashboard_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_calls_dashboard_states_id_seq OWNED BY public.user_col_pref_calls_dashboard_states.id;


--
-- TOC entry 674 (class 1259 OID 95408)
-- Name: user_col_pref_clicks_dashboards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_clicks_dashboards (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    state_queries boolean DEFAULT false,
    state_searches boolean DEFAULT false,
    state_cost boolean DEFAULT false,
    state_impressions boolean DEFAULT false,
    state_clicks boolean DEFAULT false,
    state_ctr boolean DEFAULT false,
    state_avg_cpc boolean DEFAULT false,
    state_avg_bid boolean DEFAULT false,
    state_avg_pos boolean DEFAULT false,
    source_queries boolean DEFAULT false,
    source_searches boolean DEFAULT false,
    source_cost boolean DEFAULT false,
    source_impressions boolean DEFAULT false,
    source_clicks boolean DEFAULT false,
    source_ctr boolean DEFAULT false,
    source_avg_cpc boolean DEFAULT false,
    source_avg_bid boolean DEFAULT false,
    source_avg_pos boolean DEFAULT false,
    creative_queries boolean DEFAULT false,
    creative_searches boolean DEFAULT false,
    creative_cost boolean DEFAULT false,
    creative_impressions boolean DEFAULT false,
    creative_clicks boolean DEFAULT false,
    creative_ctr boolean DEFAULT false,
    creative_avg_cpc boolean DEFAULT false,
    creative_avg_bid boolean DEFAULT false,
    creative_avg_pos boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    insurance_type_queries boolean DEFAULT false,
    insurance_type_searches boolean DEFAULT false,
    insurance_type_cost boolean DEFAULT false,
    insurance_type_impressions boolean DEFAULT false,
    insurance_type_clicks boolean DEFAULT false,
    insurance_type_ctr boolean DEFAULT false,
    insurance_type_avg_cpc boolean DEFAULT false,
    insurance_type_avg_bid boolean DEFAULT false,
    insurance_type_avg_pos boolean DEFAULT false,
    state_total_leads boolean DEFAULT false,
    state_total_calls boolean DEFAULT false,
    source_total_leads boolean DEFAULT false,
    source_total_calls boolean DEFAULT false,
    creative_total_leads boolean DEFAULT false,
    creative_total_calls boolean DEFAULT false,
    insurance_type_total_leads boolean DEFAULT false,
    insurance_type_total_calls boolean DEFAULT false
);


ALTER TABLE public.user_col_pref_clicks_dashboards OWNER TO postgres;

--
-- TOC entry 675 (class 1259 OID 95455)
-- Name: user_col_pref_clicks_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_clicks_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_clicks_dashboards_id_seq OWNER TO postgres;

--
-- TOC entry 7863 (class 0 OID 0)
-- Dependencies: 675
-- Name: user_col_pref_clicks_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_clicks_dashboards_id_seq OWNED BY public.user_col_pref_clicks_dashboards.id;


--
-- TOC entry 676 (class 1259 OID 95457)
-- Name: user_col_pref_conversion_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_conversion_logs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    log_status boolean DEFAULT false,
    log_product_type boolean DEFAULT false,
    log_event boolean DEFAULT false,
    log_progress boolean DEFAULT false,
    log_total_records boolean DEFAULT false,
    log_time boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    log_total_revenue boolean DEFAULT false
);


ALTER TABLE public.user_col_pref_conversion_logs OWNER TO postgres;

--
-- TOC entry 677 (class 1259 OID 95467)
-- Name: user_col_pref_conversion_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_conversion_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_conversion_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7864 (class 0 OID 0)
-- Dependencies: 677
-- Name: user_col_pref_conversion_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_conversion_logs_id_seq OWNED BY public.user_col_pref_conversion_logs.id;


--
-- TOC entry 678 (class 1259 OID 95469)
-- Name: user_col_pref_leads_dashboards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_leads_dashboards (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    state_opportunities boolean DEFAULT false,
    state_searches boolean DEFAULT false,
    state_leads boolean DEFAULT false,
    state_won boolean DEFAULT false,
    state_cost boolean DEFAULT false,
    state_avg_cpl boolean DEFAULT false,
    campaign_opportunities boolean DEFAULT false,
    campaign_searches boolean DEFAULT false,
    campaign_leads boolean DEFAULT false,
    campaign_won boolean DEFAULT false,
    campaign_cost boolean DEFAULT false,
    campaign_avg_cpl boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    insurance_type_opportunities boolean DEFAULT false,
    insurance_type_searches boolean DEFAULT false,
    insurance_type_bid_rate boolean DEFAULT false,
    insurance_type_won boolean DEFAULT false,
    insurance_type_leads boolean DEFAULT false,
    insurance_type_cost boolean DEFAULT false,
    insurance_type_avg_cpl boolean DEFAULT false,
    state_bid_rate boolean DEFAULT false,
    state_accept_rate boolean DEFAULT false,
    state_avg_bid boolean DEFAULT false,
    campaign_bid_rate boolean DEFAULT false,
    campaign_accept_rate boolean DEFAULT false,
    campaign_avg_bid boolean DEFAULT false,
    insurance_type_avg_bid boolean DEFAULT false,
    insurance_type_accept_rate boolean DEFAULT false
);


ALTER TABLE public.user_col_pref_leads_dashboards OWNER TO postgres;

--
-- TOC entry 679 (class 1259 OID 95499)
-- Name: user_col_pref_leads_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_leads_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_leads_dashboards_id_seq OWNER TO postgres;

--
-- TOC entry 7865 (class 0 OID 0)
-- Dependencies: 679
-- Name: user_col_pref_leads_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_leads_dashboards_id_seq OWNED BY public.user_col_pref_leads_dashboards.id;


--
-- TOC entry 680 (class 1259 OID 95501)
-- Name: user_col_pref_syndi_clicks_dashboards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_col_pref_syndi_clicks_dashboards (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    state_queries boolean DEFAULT false,
    state_searches boolean DEFAULT false,
    state_cost boolean DEFAULT false,
    state_impressions boolean DEFAULT false,
    state_clicks boolean DEFAULT false,
    state_ctr boolean DEFAULT false,
    state_avg_cpc boolean DEFAULT false,
    state_avg_bid boolean DEFAULT false,
    state_avg_pos boolean DEFAULT false,
    state_avg_rpc boolean DEFAULT false,
    state_profit boolean DEFAULT false,
    state_cm boolean DEFAULT false,
    state_gp_per boolean DEFAULT false,
    state_spend boolean DEFAULT false,
    source_queries boolean DEFAULT false,
    source_searches boolean DEFAULT false,
    source_cost boolean DEFAULT false,
    source_impressions boolean DEFAULT false,
    source_clicks boolean DEFAULT false,
    source_ctr boolean DEFAULT false,
    source_avg_cpc boolean DEFAULT false,
    source_avg_bid boolean DEFAULT false,
    source_avg_pos boolean DEFAULT false,
    source_avg_rpc boolean DEFAULT false,
    source_profit boolean DEFAULT false,
    source_cm boolean DEFAULT false,
    source_gp_per boolean DEFAULT false,
    source_spend boolean DEFAULT false,
    insurance_type_queries boolean DEFAULT false,
    insurance_type_searches boolean DEFAULT false,
    insurance_type_cost boolean DEFAULT false,
    insurance_type_impressions boolean DEFAULT false,
    insurance_type_clicks boolean DEFAULT false,
    insurance_type_ctr boolean DEFAULT false,
    insurance_type_avg_cpc boolean DEFAULT false,
    insurance_type_avg_bid boolean DEFAULT false,
    insurance_type_avg_pos boolean DEFAULT false,
    insurance_type_avg_rpc boolean DEFAULT false,
    insurance_type_profit boolean DEFAULT false,
    insurance_type_cm boolean DEFAULT false,
    insurance_type_gp_per boolean DEFAULT false,
    insurance_type_spend boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_col_pref_syndi_clicks_dashboards OWNER TO postgres;

--
-- TOC entry 681 (class 1259 OID 95546)
-- Name: user_col_pref_syndi_clicks_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_col_pref_syndi_clicks_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_col_pref_syndi_clicks_dashboards_id_seq OWNER TO postgres;

--
-- TOC entry 7866 (class 0 OID 0)
-- Dependencies: 681
-- Name: user_col_pref_syndi_clicks_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_col_pref_syndi_clicks_dashboards_id_seq OWNED BY public.user_col_pref_syndi_clicks_dashboards.id;


--
-- TOC entry 682 (class 1259 OID 95548)
-- Name: user_column_preference_ad_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_ad_groups (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    click_analytic_queries boolean DEFAULT false,
    click_analytic_searches boolean DEFAULT false,
    click_analytic_impressions boolean DEFAULT false,
    click_analytic_clicks boolean DEFAULT false,
    click_analytic_total_payout boolean DEFAULT false,
    click_analytic_ctr boolean DEFAULT false,
    click_analytic_cpc boolean DEFAULT false,
    click_analytic_avg_bid boolean DEFAULT false,
    click_analytic_avg_position boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    profit boolean DEFAULT false,
    contribution_margin boolean DEFAULT false,
    is_inventory boolean DEFAULT false,
    is_opportunities boolean DEFAULT false,
    is_target_rate boolean DEFAULT false,
    is_searches boolean DEFAULT false,
    is_bid_rate boolean DEFAULT false,
    is_impressions boolean DEFAULT false,
    is_total_clicks boolean DEFAULT false,
    is_ctr boolean DEFAULT false,
    is_avg_bid boolean DEFAULT false,
    is_avg_cpc boolean DEFAULT false,
    is_total_cost boolean DEFAULT false,
    is_ad_group_notes boolean DEFAULT false,
    is_pii boolean DEFAULT false,
    is_full_data boolean DEFAULT false,
    is_total_leads boolean DEFAULT false,
    is_total_calls boolean DEFAULT false,
    is_rtb_cm boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_ad_groups OWNER TO postgres;

--
-- TOC entry 683 (class 1259 OID 95579)
-- Name: user_column_preference_ad_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_ad_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_ad_groups_id_seq OWNER TO postgres;

--
-- TOC entry 7867 (class 0 OID 0)
-- Dependencies: 683
-- Name: user_column_preference_ad_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_ad_groups_id_seq OWNED BY public.user_column_preference_ad_groups.id;


--
-- TOC entry 684 (class 1259 OID 95581)
-- Name: user_column_preference_call_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_call_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    call_analytic_opportunities boolean DEFAULT false,
    call_analytic_searches boolean DEFAULT false,
    call_analytic_total_calls boolean DEFAULT false,
    call_analytic_total_cost boolean DEFAULT false,
    call_analytic_avg_cpc boolean DEFAULT false,
    call_analytic_total_call_duration boolean DEFAULT false,
    call_analytic_avg_call_duration boolean DEFAULT false,
    call_analytic_billable_calls boolean DEFAULT false,
    call_analytic_distinct_calls boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_call_inventory boolean DEFAULT false,
    is_call_opportunities boolean DEFAULT false,
    is_call_target_rate boolean DEFAULT false,
    is_call_searches boolean DEFAULT false,
    is_call_bid_rate boolean DEFAULT false,
    is_call_transfers boolean DEFAULT false,
    is_call_accepted boolean DEFAULT false,
    is_call_accept_rate boolean DEFAULT false,
    is_call_avg_bid boolean DEFAULT false,
    is_call_avg_cpc boolean DEFAULT false,
    is_call_total_cost boolean DEFAULT false,
    is_call_duration boolean DEFAULT false,
    is_call_wait_time boolean DEFAULT false,
    is_call_profit boolean DEFAULT false,
    is_call_cm boolean DEFAULT false,
    is_ad_group_notes boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_call_profiles OWNER TO postgres;

--
-- TOC entry 685 (class 1259 OID 95609)
-- Name: user_column_preference_call_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_call_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_call_profiles_id_seq OWNER TO postgres;

--
-- TOC entry 7868 (class 0 OID 0)
-- Dependencies: 685
-- Name: user_column_preference_call_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_call_profiles_id_seq OWNED BY public.user_column_preference_call_profiles.id;


--
-- TOC entry 686 (class 1259 OID 95611)
-- Name: user_column_preference_call_source_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_call_source_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    call_analytic_opportunities boolean DEFAULT false,
    call_analytic_searches boolean DEFAULT false,
    call_analytic_total_calls boolean DEFAULT false,
    call_analytic_avg_cpc boolean DEFAULT false,
    call_analytic_total_call_duration boolean DEFAULT false,
    call_analytic_avg_call_duration boolean DEFAULT false,
    call_analytic_billable_calls boolean DEFAULT false,
    call_analytic_distinct_calls boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_call_inventory boolean DEFAULT false,
    is_call_opportunities boolean DEFAULT false,
    is_call_target_rate boolean DEFAULT false,
    is_call_searches boolean DEFAULT false,
    is_call_bid_rate boolean DEFAULT false,
    is_call_transfers boolean DEFAULT false,
    is_call_accepted boolean DEFAULT false,
    is_call_accept_rate boolean DEFAULT false,
    is_call_avg_bid boolean DEFAULT false,
    is_call_avg_cpc boolean DEFAULT false,
    is_call_total_cost boolean DEFAULT false,
    is_call_call_duration boolean DEFAULT false,
    is_call_wait_time boolean DEFAULT false,
    is_call_profit boolean DEFAULT true,
    is_call_cm boolean DEFAULT true,
    is_source_setting_notes boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_call_source_settings OWNER TO postgres;

--
-- TOC entry 687 (class 1259 OID 95638)
-- Name: user_column_preference_call_source_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_call_source_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_call_source_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7869 (class 0 OID 0)
-- Dependencies: 687
-- Name: user_column_preference_call_source_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_call_source_settings_id_seq OWNED BY public.user_column_preference_call_source_settings.id;


--
-- TOC entry 688 (class 1259 OID 95640)
-- Name: user_column_preference_calls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_calls (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    call_name boolean DEFAULT false,
    call_phone boolean DEFAULT false,
    call_duration boolean DEFAULT false,
    call_state boolean DEFAULT false,
    call_received boolean DEFAULT false,
    call_recording boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    call_insured boolean DEFAULT false,
    call_address boolean DEFAULT false,
    call_zip_code boolean DEFAULT false,
    call_city boolean DEFAULT false,
    call_vehicles boolean DEFAULT false,
    call_drivers boolean DEFAULT false,
    call_lead_type boolean DEFAULT false,
    call_campaign_name boolean DEFAULT false,
    call_status boolean DEFAULT false,
    status boolean DEFAULT false,
    cost boolean DEFAULT false,
    profile boolean DEFAULT false,
    transfer_type boolean DEFAULT false,
    duplicate boolean DEFAULT false,
    call_refund_status boolean DEFAULT false,
    aid boolean DEFAULT false,
    cid boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_calls OWNER TO postgres;

--
-- TOC entry 689 (class 1259 OID 95666)
-- Name: user_column_preference_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_calls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_calls_id_seq OWNER TO postgres;

--
-- TOC entry 7870 (class 0 OID 0)
-- Dependencies: 689
-- Name: user_column_preference_calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_calls_id_seq OWNED BY public.user_column_preference_calls.id;


--
-- TOC entry 690 (class 1259 OID 95668)
-- Name: user_column_preference_campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_campaigns (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    product_type boolean DEFAULT false,
    lead_type boolean DEFAULT false,
    daily_budget boolean DEFAULT false,
    monthly_budget boolean DEFAULT false,
    click_analytic_searches boolean DEFAULT false,
    click_analytic_impressions boolean DEFAULT false,
    click_analytic_clicks boolean DEFAULT false,
    click_analytic_cpc boolean DEFAULT false,
    click_analytic_total_payout boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    contribution_margin boolean DEFAULT false,
    profit boolean DEFAULT false,
    click_analytic_queries boolean DEFAULT false,
    is_lead_product boolean DEFAULT false,
    is_lead_type boolean DEFAULT false,
    is_lead_daily_limit boolean DEFAULT false,
    is_lead_monthly_limit boolean DEFAULT false,
    is_lead_inventory boolean DEFAULT false,
    is_lead_opportunities boolean DEFAULT false,
    is_lead_target_rate boolean DEFAULT false,
    is_lead_bids boolean DEFAULT false,
    is_lead_bid_rate boolean DEFAULT false,
    is_lead_posts boolean DEFAULT false,
    is_lead_accepted boolean DEFAULT false,
    is_lead_accept_rate boolean DEFAULT false,
    is_lead_avg_bid boolean DEFAULT false,
    is_lead_avg_cpl boolean DEFAULT false,
    is_lead_spend boolean DEFAULT false,
    is_call_product boolean DEFAULT false,
    is_call_type boolean DEFAULT false,
    is_call_daily_limit boolean DEFAULT false,
    is_call_monthly_limit boolean DEFAULT false,
    is_call_inventory boolean DEFAULT false,
    is_call_opportunities boolean DEFAULT false,
    is_call_target_rate boolean DEFAULT false,
    is_call_bids boolean DEFAULT false,
    is_call_bid_rate boolean DEFAULT false,
    is_call_transfers boolean DEFAULT false,
    is_call_accepted boolean DEFAULT false,
    is_call_accept_rate boolean DEFAULT false,
    is_call_avg_bid boolean DEFAULT false,
    is_call_avg_cpc boolean DEFAULT false,
    is_call_spend boolean DEFAULT false,
    is_call_avg_duration boolean DEFAULT false,
    is_lead_profit boolean DEFAULT false,
    is_lead_cm boolean DEFAULT false,
    is_call_profit boolean DEFAULT false,
    is_call_cm boolean DEFAULT false,
    is_click_inventory boolean DEFAULT false,
    is_click_opportunities boolean DEFAULT false,
    is_click_target_rate boolean DEFAULT false,
    is_click_bids boolean DEFAULT false,
    is_click_bid_rate boolean DEFAULT false,
    is_click_impressions boolean DEFAULT false,
    is_click_total_clicks boolean DEFAULT false,
    is_click_success_rate boolean DEFAULT false,
    is_click_avg_bid boolean DEFAULT false,
    is_click_avg_cpc boolean DEFAULT false,
    is_click_total_cost boolean DEFAULT false,
    is_click_profit boolean DEFAULT false,
    is_click_cm boolean DEFAULT false,
    is_click_product boolean DEFAULT false,
    is_click_type boolean DEFAULT false,
    is_click_daily_limit boolean DEFAULT false,
    is_click_monthly_limit boolean DEFAULT false,
    is_generic_units boolean DEFAULT false,
    is_generic_avg_bid boolean DEFAULT false,
    is_generic_cpx boolean DEFAULT false,
    is_generic_spend boolean DEFAULT false,
    is_campaign_pace boolean DEFAULT false,
    is_campaign_notes boolean DEFAULT false,
    is_click_total_leads boolean DEFAULT false,
    is_click_total_calls boolean DEFAULT false,
    is_prefill_success_rate boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_campaigns OWNER TO postgres;

--
-- TOC entry 691 (class 1259 OID 95744)
-- Name: user_column_preference_campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_campaigns_id_seq OWNER TO postgres;

--
-- TOC entry 7871 (class 0 OID 0)
-- Dependencies: 691
-- Name: user_column_preference_campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_campaigns_id_seq OWNED BY public.user_column_preference_campaigns.id;


--
-- TOC entry 692 (class 1259 OID 95746)
-- Name: user_column_preference_lead_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_lead_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    lead_analytic_opportunities boolean DEFAULT false,
    lead_analytic_searches boolean DEFAULT false,
    lead_analytic_won boolean DEFAULT false,
    lead_analytic_total_leads boolean DEFAULT false,
    lead_analytic_total_cost boolean DEFAULT false,
    lead_analytic_avg_cpl boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_lead_inventory boolean DEFAULT false,
    is_lead_opportunities boolean DEFAULT false,
    is_lead_target_rate boolean DEFAULT false,
    is_lead_searches boolean DEFAULT false,
    is_lead_bid_rate boolean DEFAULT false,
    is_lead_won boolean DEFAULT false,
    is_lead_accepted boolean DEFAULT false,
    is_lead_accept_rate boolean DEFAULT false,
    is_lead_avg_bid boolean DEFAULT false,
    is_lead_avg_cpl boolean DEFAULT false,
    is_lead_total_cost boolean DEFAULT false,
    is_lead_profit boolean DEFAULT false,
    is_lead_cm boolean DEFAULT false,
    is_ad_group_notes boolean DEFAULT false,
    lead_analytic_total_opportunities boolean DEFAULT false,
    lead_analytic_total_won boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_lead_profiles OWNER TO postgres;

--
-- TOC entry 693 (class 1259 OID 95771)
-- Name: user_column_preference_lead_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_lead_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_lead_profiles_id_seq OWNER TO postgres;

--
-- TOC entry 7872 (class 0 OID 0)
-- Dependencies: 693
-- Name: user_column_preference_lead_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_lead_profiles_id_seq OWNED BY public.user_column_preference_lead_profiles.id;


--
-- TOC entry 694 (class 1259 OID 95773)
-- Name: user_column_preference_lead_source_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_lead_source_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    lead_analytic_opportunities boolean DEFAULT false,
    lead_analytic_searches boolean DEFAULT false,
    lead_analytic_won boolean DEFAULT false,
    lead_analytic_selected boolean DEFAULT false,
    lead_analytic_total_leads boolean DEFAULT false,
    lead_analytic_total_cost boolean DEFAULT false,
    lead_analytic_avg_cpl boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_lead_inventory boolean DEFAULT false,
    is_lead_opportunities boolean DEFAULT false,
    is_lead_target_rate boolean DEFAULT false,
    is_lead_searches boolean DEFAULT false,
    is_lead_bid_rate boolean DEFAULT false,
    is_lead_won boolean DEFAULT false,
    is_lead_accepted boolean DEFAULT false,
    is_lead_accept_rate boolean DEFAULT false,
    is_lead_avg_bid boolean DEFAULT false,
    is_lead_avg_cpl boolean DEFAULT false,
    is_lead_total_cost boolean DEFAULT false,
    is_lead_profit boolean DEFAULT true,
    is_lead_cm boolean DEFAULT true,
    is_source_setting_notes boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_lead_source_settings OWNER TO postgres;

--
-- TOC entry 695 (class 1259 OID 95797)
-- Name: user_column_preference_lead_source_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_lead_source_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_lead_source_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7873 (class 0 OID 0)
-- Dependencies: 695
-- Name: user_column_preference_lead_source_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_lead_source_settings_id_seq OWNED BY public.user_column_preference_lead_source_settings.id;


--
-- TOC entry 696 (class 1259 OID 95799)
-- Name: user_column_preference_leads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_leads (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    lead_name boolean DEFAULT false,
    lead_phone boolean DEFAULT false,
    lead_email boolean DEFAULT false,
    lead_state boolean DEFAULT false,
    lead_type boolean DEFAULT false,
    lead_created_at boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lead_brand boolean DEFAULT false,
    lead_campaign_name boolean DEFAULT false,
    lead_status boolean DEFAULT false,
    lead_refund_status boolean DEFAULT false,
    lead_cost boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_leads OWNER TO postgres;

--
-- TOC entry 697 (class 1259 OID 95813)
-- Name: user_column_preference_leads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_leads_id_seq OWNER TO postgres;

--
-- TOC entry 7874 (class 0 OID 0)
-- Dependencies: 697
-- Name: user_column_preference_leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_leads_id_seq OWNED BY public.user_column_preference_leads.id;


--
-- TOC entry 698 (class 1259 OID 95815)
-- Name: user_column_preference_prospects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_prospects (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    prospect_name boolean DEFAULT true,
    prospect_phone boolean DEFAULT false,
    prospect_email boolean DEFAULT false,
    prospect_campaign_name boolean DEFAULT false,
    prospect_type boolean DEFAULT false,
    prospect_ad_group boolean DEFAULT false,
    prospect_brand boolean DEFAULT false,
    prospect_disposition boolean DEFAULT false,
    prospect_insured boolean DEFAULT false,
    prospect_address boolean DEFAULT false,
    prospect_city boolean DEFAULT false,
    prospect_zip_code boolean DEFAULT false,
    prospect_received boolean DEFAULT false,
    prospect_applicants boolean DEFAULT false,
    prospect_vehicles boolean DEFAULT false,
    prospect_status boolean DEFAULT false,
    prospect_duration boolean DEFAULT false,
    prospect_state boolean DEFAULT false,
    prospect_recording boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_column_preference_prospects OWNER TO postgres;

--
-- TOC entry 699 (class 1259 OID 95837)
-- Name: user_column_preference_prospects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_prospects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_prospects_id_seq OWNER TO postgres;

--
-- TOC entry 7875 (class 0 OID 0)
-- Dependencies: 699
-- Name: user_column_preference_prospects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_prospects_id_seq OWNED BY public.user_column_preference_prospects.id;


--
-- TOC entry 700 (class 1259 OID 95839)
-- Name: user_column_preference_source_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_column_preference_source_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    click_analytic_queries boolean DEFAULT false,
    click_analytic_searches boolean DEFAULT false,
    click_analytic_impressions boolean DEFAULT false,
    click_analytic_clicks boolean DEFAULT false,
    click_analytic_total_payout boolean DEFAULT false,
    click_analytic_ctr boolean DEFAULT false,
    click_analytic_cpc boolean DEFAULT false,
    click_analytic_avg_bid boolean DEFAULT false,
    click_analytic_avg_position boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    profit boolean DEFAULT false,
    contribution_margin boolean DEFAULT false,
    is_inventory boolean DEFAULT false,
    is_opportunities boolean DEFAULT false,
    is_target_rate boolean DEFAULT false,
    is_searches boolean DEFAULT false,
    is_bid_rate boolean DEFAULT false,
    is_impressions boolean DEFAULT false,
    is_total_clicks boolean DEFAULT false,
    is_ctr boolean DEFAULT false,
    is_avg_bid boolean DEFAULT false,
    is_avg_cpc boolean DEFAULT false,
    is_total_cost boolean DEFAULT false,
    is_source_setting_notes boolean DEFAULT false,
    is_pii boolean DEFAULT false,
    is_full_data boolean DEFAULT false,
    is_total_leads boolean DEFAULT false,
    is_total_calls boolean DEFAULT false
);


ALTER TABLE public.user_column_preference_source_settings OWNER TO postgres;

--
-- TOC entry 701 (class 1259 OID 95869)
-- Name: user_column_preference_source_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_column_preference_source_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_column_preference_source_settings_id_seq OWNER TO postgres;

--
-- TOC entry 7876 (class 0 OID 0)
-- Dependencies: 701
-- Name: user_column_preference_source_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_column_preference_source_settings_id_seq OWNED BY public.user_column_preference_source_settings.id;


--
-- TOC entry 702 (class 1259 OID 95871)
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_notifications (
    id bigint NOT NULL,
    user_id bigint,
    banner_type character varying,
    message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status character varying,
    admin_user_id bigint,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.user_notifications OWNER TO postgres;

--
-- TOC entry 703 (class 1259 OID 95877)
-- Name: user_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_notifications_id_seq OWNER TO postgres;

--
-- TOC entry 7877 (class 0 OID 0)
-- Dependencies: 703
-- Name: user_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_notifications_id_seq OWNED BY public.user_notifications.id;


--
-- TOC entry 704 (class 1259 OID 95879)
-- Name: user_smart_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_smart_views (
    id bigint NOT NULL,
    name character varying NOT NULL,
    user_id bigint NOT NULL,
    smart_view_filters jsonb,
    smart_view_group_bys jsonb,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    hide boolean DEFAULT false,
    individual_clicks boolean DEFAULT false,
    individual_calls boolean DEFAULT false,
    product_type_id bigint NOT NULL,
    individual_leads boolean DEFAULT false,
    config jsonb
);


ALTER TABLE public.user_smart_views OWNER TO postgres;

--
-- TOC entry 705 (class 1259 OID 95889)
-- Name: user_smart_views_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_smart_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_smart_views_id_seq OWNER TO postgres;

--
-- TOC entry 7878 (class 0 OID 0)
-- Dependencies: 705
-- Name: user_smart_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_smart_views_id_seq OWNED BY public.user_smart_views.id;


--
-- TOC entry 706 (class 1259 OID 95891)
-- Name: user_terms_of_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_terms_of_services (
    id bigint NOT NULL,
    name character varying,
    url character varying,
    accepted_by integer,
    account_id integer,
    terms_of_service_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    doc_id character varying,
    user_ip character varying
);


ALTER TABLE public.user_terms_of_services OWNER TO postgres;

--
-- TOC entry 707 (class 1259 OID 95897)
-- Name: user_terms_of_services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_terms_of_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_terms_of_services_id_seq OWNER TO postgres;

--
-- TOC entry 7879 (class 0 OID 0)
-- Dependencies: 707
-- Name: user_terms_of_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_terms_of_services_id_seq OWNED BY public.user_terms_of_services.id;


--
-- TOC entry 708 (class 1259 OID 95899)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    first_name character varying,
    last_name character varying,
    company_name character varying,
    phone_num character varying,
    timezone character varying,
    address character varying,
    city character varying,
    state character varying,
    zip_code bigint,
    discarded_at timestamp(6) without time zone,
    is_mfa_enabled boolean DEFAULT false,
    is_email_otp_enabled boolean DEFAULT true,
    otp_secret text,
    last_otp_at timestamp(6) without time zone,
    access_role character varying,
    carrier character varying,
    license character varying,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 709 (class 1259 OID 95910)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 7880 (class 0 OID 0)
-- Dependencies: 709
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 710 (class 1259 OID 95912)
-- Name: versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    item_type character varying NOT NULL,
    item_id bigint NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object json,
    created_at timestamp(6) without time zone,
    object_changes json,
    transaction_id integer,
    item_name character varying,
    account_id bigint,
    fk_id bigint,
    fk_name character varying,
    fk_type character varying,
    brand_id bigint,
    campaign_id bigint,
    admin_user_id bigint
);


ALTER TABLE public.versions OWNER TO postgres;

--
-- TOC entry 711 (class 1259 OID 95918)
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.versions_id_seq OWNER TO postgres;

--
-- TOC entry 7881 (class 0 OID 0)
-- Dependencies: 711
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- TOC entry 712 (class 1259 OID 95920)
-- Name: violation_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.violation_types (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.violation_types OWNER TO postgres;

--
-- TOC entry 713 (class 1259 OID 95926)
-- Name: violation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.violation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.violation_types_id_seq OWNER TO postgres;

--
-- TOC entry 7882 (class 0 OID 0)
-- Dependencies: 713
-- Name: violation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.violation_types_id_seq OWNED BY public.violation_types.id;


--
-- TOC entry 714 (class 1259 OID 95928)
-- Name: white_listing_brands; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.white_listing_brands (
    id bigint NOT NULL,
    name character varying,
    admin_portal_url character varying,
    api_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    brand_contact_number character varying,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.white_listing_brands OWNER TO postgres;

--
-- TOC entry 715 (class 1259 OID 95934)
-- Name: white_listing_brands_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.white_listing_brands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.white_listing_brands_id_seq OWNER TO postgres;

--
-- TOC entry 7883 (class 0 OID 0)
-- Dependencies: 715
-- Name: white_listing_brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.white_listing_brands_id_seq OWNED BY public.white_listing_brands.id;


--
-- TOC entry 716 (class 1259 OID 95936)
-- Name: whitelabeled_brands_user_login_mappings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.whitelabeled_brands_user_login_mappings (
    id bigint NOT NULL,
    white_listing_brand_id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    whitelabeled_brand_admin_user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.whitelabeled_brands_user_login_mappings OWNER TO postgres;

--
-- TOC entry 717 (class 1259 OID 95939)
-- Name: whitelabeled_brands_user_login_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.whitelabeled_brands_user_login_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.whitelabeled_brands_user_login_mappings_id_seq OWNER TO postgres;

--
-- TOC entry 7884 (class 0 OID 0)
-- Dependencies: 717
-- Name: whitelabeled_brands_user_login_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.whitelabeled_brands_user_login_mappings_id_seq OWNED BY public.whitelabeled_brands_user_login_mappings.id;


--
-- TOC entry 718 (class 1259 OID 95941)
-- Name: whitelisting_brand_admin_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.whitelisting_brand_admin_assignments (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    white_listing_brand_id bigint NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.whitelisting_brand_admin_assignments OWNER TO postgres;

--
-- TOC entry 719 (class 1259 OID 95944)
-- Name: whitelisting_brand_admin_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.whitelisting_brand_admin_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.whitelisting_brand_admin_assignments_id_seq OWNER TO postgres;

--
-- TOC entry 7885 (class 0 OID 0)
-- Dependencies: 719
-- Name: whitelisting_brand_admin_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.whitelisting_brand_admin_assignments_id_seq OWNED BY public.whitelisting_brand_admin_assignments.id;


--
-- TOC entry 720 (class 1259 OID 95946)
-- Name: zip_tier_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zip_tier_locations (
    id bigint NOT NULL,
    zip_tier_id integer,
    zip character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.zip_tier_locations OWNER TO postgres;

--
-- TOC entry 721 (class 1259 OID 95952)
-- Name: zip_tier_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zip_tier_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zip_tier_locations_id_seq OWNER TO postgres;

--
-- TOC entry 7886 (class 0 OID 0)
-- Dependencies: 721
-- Name: zip_tier_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zip_tier_locations_id_seq OWNED BY public.zip_tier_locations.id;


--
-- TOC entry 722 (class 1259 OID 95954)
-- Name: zip_tiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zip_tiers (
    id bigint NOT NULL,
    name character varying,
    account_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


ALTER TABLE public.zip_tiers OWNER TO postgres;

--
-- TOC entry 723 (class 1259 OID 95960)
-- Name: zip_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zip_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zip_tiers_id_seq OWNER TO postgres;

--
-- TOC entry 7887 (class 0 OID 0)
-- Dependencies: 723
-- Name: zip_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zip_tiers_id_seq OWNED BY public.zip_tiers.id;


--
-- TOC entry 724 (class 1259 OID 95962)
-- Name: zipcodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zipcodes (
    id bigint NOT NULL,
    zipcode character varying NOT NULL,
    state character varying,
    city character varying,
    latitude double precision,
    longitude double precision,
    areacode character varying,
    county character varying,
    timezone_offset character varying,
    timezone character varying,
    pop integer,
    dst character varying,
    geom character varying
);


ALTER TABLE public.zipcodes OWNER TO postgres;

--
-- TOC entry 725 (class 1259 OID 95968)
-- Name: zipcodes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zipcodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zipcodes_id_seq OWNER TO postgres;

--
-- TOC entry 7888 (class 0 OID 0)
-- Dependencies: 725
-- Name: zipcodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zipcodes_id_seq OWNED BY public.zipcodes.id;


--
-- TOC entry 4708 (class 2604 OID 95970)
-- Name: access_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_tokens ALTER COLUMN id SET DEFAULT nextval('public.access_tokens_id_seq'::regclass);


--
-- TOC entry 4710 (class 2604 OID 95971)
-- Name: account_balances id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_balances ALTER COLUMN id SET DEFAULT nextval('public.account_balances_id_seq'::regclass);


--
-- TOC entry 4714 (class 2604 OID 95972)
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- TOC entry 4737 (class 2604 OID 95973)
-- Name: ad_contents id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_contents ALTER COLUMN id SET DEFAULT nextval('public.ad_contents_id_seq'::regclass);


--
-- TOC entry 4738 (class 2604 OID 95974)
-- Name: ad_group_ads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_ads ALTER COLUMN id SET DEFAULT nextval('public.ad_group_ads_id_seq'::regclass);


--
-- TOC entry 4741 (class 2604 OID 95975)
-- Name: ad_group_filter_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filter_groups ALTER COLUMN id SET DEFAULT nextval('public.ad_group_filter_groups_id_seq'::regclass);


--
-- TOC entry 4742 (class 2604 OID 95976)
-- Name: ad_group_filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filters ALTER COLUMN id SET DEFAULT nextval('public.ad_group_filters_id_seq'::regclass);


--
-- TOC entry 4745 (class 2604 OID 95977)
-- Name: ad_group_locations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_locations ALTER COLUMN id SET DEFAULT nextval('public.ad_group_locations_id_seq'::regclass);


--
-- TOC entry 4746 (class 2604 OID 95978)
-- Name: ad_group_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_notes ALTER COLUMN id SET DEFAULT nextval('public.ad_group_notes_id_seq'::regclass);


--
-- TOC entry 4747 (class 2604 OID 95979)
-- Name: ad_group_pixel_columns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_pixel_columns ALTER COLUMN id SET DEFAULT nextval('public.ad_group_pixel_columns_id_seq'::regclass);


--
-- TOC entry 4756 (class 2604 OID 95980)
-- Name: ad_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_groups ALTER COLUMN id SET DEFAULT nextval('public.ad_groups_id_seq'::regclass);


--
-- TOC entry 4757 (class 2604 OID 95981)
-- Name: admin_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_assignments ALTER COLUMN id SET DEFAULT nextval('public.admin_assignments_id_seq'::regclass);


--
-- TOC entry 4758 (class 2604 OID 95982)
-- Name: admin_clients_customize_columns_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_clients_customize_columns_orders ALTER COLUMN id SET DEFAULT nextval('public.admin_clients_customize_columns_orders_id_seq'::regclass);


--
-- TOC entry 4791 (class 2604 OID 95983)
-- Name: admin_features id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_features ALTER COLUMN id SET DEFAULT nextval('public.admin_features_id_seq'::regclass);


--
-- TOC entry 4792 (class 2604 OID 95984)
-- Name: admin_notification_template_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_template_types ALTER COLUMN id SET DEFAULT nextval('public.admin_notification_template_types_id_seq'::regclass);


--
-- TOC entry 4793 (class 2604 OID 95985)
-- Name: admin_notification_templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_templates ALTER COLUMN id SET DEFAULT nextval('public.admin_notification_templates_id_seq'::regclass);


--
-- TOC entry 4794 (class 2604 OID 95986)
-- Name: admin_notification_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_types ALTER COLUMN id SET DEFAULT nextval('public.admin_notification_types_id_seq'::regclass);


--
-- TOC entry 4795 (class 2604 OID 95987)
-- Name: admin_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions ALTER COLUMN id SET DEFAULT nextval('public.admin_permissions_id_seq'::regclass);


--
-- TOC entry 4797 (class 2604 OID 95988)
-- Name: admin_roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_roles ALTER COLUMN id SET DEFAULT nextval('public.admin_roles_id_seq'::regclass);


--
-- TOC entry 4798 (class 2604 OID 95989)
-- Name: admin_slack_notification_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_slack_notification_logs ALTER COLUMN id SET DEFAULT nextval('public.admin_slack_notification_logs_id_seq'::regclass);


--
-- TOC entry 4799 (class 2604 OID 95990)
-- Name: admin_user_col_pref_user_activities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_col_pref_user_activities ALTER COLUMN id SET DEFAULT nextval('public.admin_user_col_pref_user_activities_id_seq'::regclass);


--
-- TOC entry 4827 (class 2604 OID 95991)
-- Name: admin_user_column_preferences id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_column_preferences ALTER COLUMN id SET DEFAULT nextval('public.admin_user_column_preferences_id_seq'::regclass);


--
-- TOC entry 4862 (class 2604 OID 95992)
-- Name: admin_user_customize_column_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_customize_column_orders ALTER COLUMN id SET DEFAULT nextval('public.admin_user_customize_column_orders_id_seq'::regclass);


--
-- TOC entry 4863 (class 2604 OID 95993)
-- Name: admin_user_notifications_preferences id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_notifications_preferences ALTER COLUMN id SET DEFAULT nextval('public.admin_user_notifications_preferences_id_seq'::regclass);


--
-- TOC entry 4867 (class 2604 OID 95994)
-- Name: admin_user_smart_views id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_smart_views ALTER COLUMN id SET DEFAULT nextval('public.admin_user_smart_views_id_seq'::regclass);


--
-- TOC entry 4868 (class 2604 OID 95995)
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- TOC entry 4878 (class 2604 OID 95996)
-- Name: ads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ads ALTER COLUMN id SET DEFAULT nextval('public.ads_id_seq'::regclass);


--
-- TOC entry 4879 (class 2604 OID 95997)
-- Name: agent_profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_profiles ALTER COLUMN id SET DEFAULT nextval('public.agent_profiles_id_seq'::regclass);


--
-- TOC entry 4883 (class 2604 OID 95998)
-- Name: ahoy_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ahoy_events ALTER COLUMN id SET DEFAULT nextval('public.ahoy_events_id_seq'::regclass);


--
-- TOC entry 4884 (class 2604 OID 95999)
-- Name: ahoy_visits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ahoy_visits ALTER COLUMN id SET DEFAULT nextval('public.ahoy_visits_id_seq'::regclass);


--
-- TOC entry 4885 (class 2604 OID 96000)
-- Name: analytic_pixel_columns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytic_pixel_columns ALTER COLUMN id SET DEFAULT nextval('public.analytic_pixel_columns_id_seq'::regclass);


--
-- TOC entry 4898 (class 2604 OID 96001)
-- Name: analytics_export_uploads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_export_uploads ALTER COLUMN id SET DEFAULT nextval('public.analytics_export_uploads_id_seq'::regclass);


--
-- TOC entry 4899 (class 2604 OID 96002)
-- Name: analytics_exports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_exports ALTER COLUMN id SET DEFAULT nextval('public.analytics_exports_id_seq'::regclass);


--
-- TOC entry 4900 (class 2604 OID 96003)
-- Name: api_profiling_tags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_profiling_tags ALTER COLUMN id SET DEFAULT nextval('public.api_profiling_tags_id_seq'::regclass);


--
-- TOC entry 4902 (class 2604 OID 96004)
-- Name: api_timing_api_profiling_tags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_timing_api_profiling_tags ALTER COLUMN id SET DEFAULT nextval('public.api_timing_api_profiling_tags_id_seq'::regclass);


--
-- TOC entry 4904 (class 2604 OID 96005)
-- Name: api_timings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_timings ALTER COLUMN id SET DEFAULT nextval('public.api_timings_id_seq'::regclass);


--
-- TOC entry 4905 (class 2604 OID 96006)
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- TOC entry 4906 (class 2604 OID 96007)
-- Name: automation_test_execution_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_test_execution_results ALTER COLUMN id SET DEFAULT nextval('public.automation_test_execution_results_id_seq'::regclass);


--
-- TOC entry 4910 (class 2604 OID 96008)
-- Name: automation_test_suite_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_test_suite_results ALTER COLUMN id SET DEFAULT nextval('public.automation_test_suite_results_id_seq'::regclass);


--
-- TOC entry 4916 (class 2604 OID 96009)
-- Name: bill_com_invoices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_invoices ALTER COLUMN id SET DEFAULT nextval('public.bill_com_invoices_id_seq'::regclass);


--
-- TOC entry 4917 (class 2604 OID 96010)
-- Name: bill_com_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_items ALTER COLUMN id SET DEFAULT nextval('public.bill_com_items_id_seq'::regclass);


--
-- TOC entry 4918 (class 2604 OID 96011)
-- Name: bill_com_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_sessions ALTER COLUMN id SET DEFAULT nextval('public.bill_com_sessions_id_seq'::regclass);


--
-- TOC entry 4919 (class 2604 OID 96012)
-- Name: billing_setting_invoice_changes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_setting_invoice_changes ALTER COLUMN id SET DEFAULT nextval('public.billing_setting_invoice_changes_id_seq'::regclass);


--
-- TOC entry 4920 (class 2604 OID 96013)
-- Name: billing_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_settings ALTER COLUMN id SET DEFAULT nextval('public.billing_settings_id_seq'::regclass);


--
-- TOC entry 4930 (class 2604 OID 96014)
-- Name: brands id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.brands ALTER COLUMN id SET DEFAULT nextval('public.brands_id_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 96015)
-- Name: call_ad_group_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ad_group_settings ALTER COLUMN id SET DEFAULT nextval('public.call_ad_group_settings_id_seq'::regclass);


--
-- TOC entry 4933 (class 2604 OID 96016)
-- Name: call_campaign_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_campaign_settings ALTER COLUMN id SET DEFAULT nextval('public.call_campaign_settings_id_seq'::regclass);


--
-- TOC entry 4947 (class 2604 OID 96017)
-- Name: call_listings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_listings ALTER COLUMN id SET DEFAULT nextval('public.call_listings_id_seq'::regclass);


--
-- TOC entry 4949 (class 2604 OID 96018)
-- Name: call_opportunities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_opportunities ALTER COLUMN id SET DEFAULT nextval('public.call_opportunities_id_seq'::regclass);


--
-- TOC entry 4950 (class 2604 OID 96019)
-- Name: call_panels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_panels ALTER COLUMN id SET DEFAULT nextval('public.call_panels_id_seq'::regclass);


--
-- TOC entry 4951 (class 2604 OID 96020)
-- Name: call_ping_debug_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ping_debug_logs ALTER COLUMN id SET DEFAULT nextval('public.call_ping_debug_logs_id_seq'::regclass);


--
-- TOC entry 4952 (class 2604 OID 96021)
-- Name: call_ping_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ping_details ALTER COLUMN id SET DEFAULT nextval('public.call_ping_details_id_seq'::regclass);


--
-- TOC entry 4953 (class 2604 OID 96022)
-- Name: call_ping_matches id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ping_matches ALTER COLUMN id SET DEFAULT nextval('public.call_ping_matches_id_seq'::regclass);


--
-- TOC entry 4954 (class 2604 OID 96023)
-- Name: call_pings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_pings ALTER COLUMN id SET DEFAULT nextval('public.call_pings_id_seq'::regclass);


--
-- TOC entry 4955 (class 2604 OID 96024)
-- Name: call_post_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_post_details ALTER COLUMN id SET DEFAULT nextval('public.call_post_details_id_seq'::regclass);


--
-- TOC entry 4956 (class 2604 OID 96025)
-- Name: call_posts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_posts ALTER COLUMN id SET DEFAULT nextval('public.call_posts_id_seq'::regclass);


--
-- TOC entry 4957 (class 2604 OID 96026)
-- Name: call_prices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_prices ALTER COLUMN id SET DEFAULT nextval('public.call_prices_id_seq'::regclass);


--
-- TOC entry 4958 (class 2604 OID 96027)
-- Name: call_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_results ALTER COLUMN id SET DEFAULT nextval('public.call_results_id_seq'::regclass);


--
-- TOC entry 4959 (class 2604 OID 96028)
-- Name: call_transcription_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_rules ALTER COLUMN id SET DEFAULT nextval('public.call_transcription_rules_id_seq'::regclass);


--
-- TOC entry 4962 (class 2604 OID 96029)
-- Name: call_transcription_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_settings ALTER COLUMN id SET DEFAULT nextval('public.call_transcription_settings_id_seq'::regclass);


--
-- TOC entry 4965 (class 2604 OID 96030)
-- Name: call_transcription_topics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_topics ALTER COLUMN id SET DEFAULT nextval('public.call_transcription_topics_id_seq'::regclass);


--
-- TOC entry 4966 (class 2604 OID 96031)
-- Name: calls_customize_columns_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.calls_customize_columns_orders ALTER COLUMN id SET DEFAULT nextval('public.calls_customize_columns_orders_id_seq'::regclass);


--
-- TOC entry 4990 (class 2604 OID 96032)
-- Name: calls_dashboard_customize_column_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.calls_dashboard_customize_column_orders ALTER COLUMN id SET DEFAULT nextval('public.calls_dashboard_customize_column_orders_id_seq'::regclass);


--
-- TOC entry 5007 (class 2604 OID 96033)
-- Name: campaign_ads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_ads ALTER COLUMN id SET DEFAULT nextval('public.campaign_ads_id_seq'::regclass);


--
-- TOC entry 5010 (class 2604 OID 96034)
-- Name: campaign_bid_modifier_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_bid_modifier_groups ALTER COLUMN id SET DEFAULT nextval('public.campaign_bid_modifier_groups_id_seq'::regclass);


--
-- TOC entry 5011 (class 2604 OID 96035)
-- Name: campaign_bid_modifiers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_bid_modifiers ALTER COLUMN id SET DEFAULT nextval('public.campaign_bid_modifiers_id_seq'::regclass);


--
-- TOC entry 5014 (class 2604 OID 96036)
-- Name: campaign_budgets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_budgets ALTER COLUMN id SET DEFAULT nextval('public.campaign_budgets_id_seq'::regclass);


--
-- TOC entry 5015 (class 2604 OID 96037)
-- Name: campaign_call_posts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_call_posts ALTER COLUMN id SET DEFAULT nextval('public.campaign_call_posts_id_seq'::regclass);


--
-- TOC entry 5016 (class 2604 OID 96038)
-- Name: campaign_dashboard_colunm_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_dashboard_colunm_orders ALTER COLUMN id SET DEFAULT nextval('public.campaign_dashboard_colunm_orders_id_seq'::regclass);


--
-- TOC entry 5025 (class 2604 OID 96039)
-- Name: campaign_filter_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filter_groups ALTER COLUMN id SET DEFAULT nextval('public.campaign_filter_groups_id_seq'::regclass);


--
-- TOC entry 5026 (class 2604 OID 96040)
-- Name: campaign_filter_packages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filter_packages ALTER COLUMN id SET DEFAULT nextval('public.campaign_filter_packages_id_seq'::regclass);


--
-- TOC entry 5027 (class 2604 OID 96041)
-- Name: campaign_filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filters ALTER COLUMN id SET DEFAULT nextval('public.campaign_filters_id_seq'::regclass);


--
-- TOC entry 5030 (class 2604 OID 96042)
-- Name: campaign_lead_integrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_lead_integrations ALTER COLUMN id SET DEFAULT nextval('public.campaign_lead_integrations_id_seq'::regclass);


--
-- TOC entry 5031 (class 2604 OID 96043)
-- Name: campaign_lead_posts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_lead_posts ALTER COLUMN id SET DEFAULT nextval('public.campaign_lead_posts_id_seq'::regclass);


--
-- TOC entry 5032 (class 2604 OID 96044)
-- Name: campaign_monthly_spends id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_monthly_spends ALTER COLUMN id SET DEFAULT nextval('public.campaign_monthly_spends_id_seq'::regclass);


--
-- TOC entry 5033 (class 2604 OID 96045)
-- Name: campaign_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_notes ALTER COLUMN id SET DEFAULT nextval('public.campaign_notes_id_seq'::regclass);


--
-- TOC entry 5034 (class 2604 OID 96046)
-- Name: campaign_pixel_columns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_pixel_columns ALTER COLUMN id SET DEFAULT nextval('public.campaign_pixel_columns_id_seq'::regclass);


--
-- TOC entry 5047 (class 2604 OID 96047)
-- Name: campaign_quote_funnels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_quote_funnels ALTER COLUMN id SET DEFAULT nextval('public.campaign_quote_funnels_id_seq'::regclass);


--
-- TOC entry 5048 (class 2604 OID 96048)
-- Name: campaign_schedules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_schedules ALTER COLUMN id SET DEFAULT nextval('public.campaign_schedules_id_seq'::regclass);


--
-- TOC entry 5050 (class 2604 OID 96049)
-- Name: campaign_source_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_source_settings ALTER COLUMN id SET DEFAULT nextval('public.campaign_source_settings_id_seq'::regclass);


--
-- TOC entry 5052 (class 2604 OID 96050)
-- Name: campaign_spends id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_spends ALTER COLUMN id SET DEFAULT nextval('public.campaign_spends_id_seq'::regclass);


--
-- TOC entry 5055 (class 2604 OID 96051)
-- Name: campaigns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN id SET DEFAULT nextval('public.campaigns_id_seq'::regclass);


--
-- TOC entry 5061 (class 2604 OID 96052)
-- Name: campaigns_customize_columns_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns_customize_columns_orders ALTER COLUMN id SET DEFAULT nextval('public.campaigns_customize_columns_orders_id_seq'::regclass);


--
-- TOC entry 5134 (class 2604 OID 96053)
-- Name: ccpa_opted_out_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ccpa_opted_out_users ALTER COLUMN id SET DEFAULT nextval('public.ccpa_opted_out_users_id_seq'::regclass);


--
-- TOC entry 5135 (class 2604 OID 96054)
-- Name: click_ad_group_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ad_group_settings ALTER COLUMN id SET DEFAULT nextval('public.click_ad_group_settings_id_seq'::regclass);


--
-- TOC entry 5137 (class 2604 OID 96055)
-- Name: click_campaign_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_campaign_settings ALTER COLUMN id SET DEFAULT nextval('public.click_campaign_settings_id_seq'::regclass);


--
-- TOC entry 5141 (class 2604 OID 96056)
-- Name: click_conversion_errors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_errors ALTER COLUMN id SET DEFAULT nextval('public.click_conversion_errors_id_seq'::regclass);


--
-- TOC entry 5142 (class 2604 OID 96057)
-- Name: click_conversion_log_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_log_details ALTER COLUMN id SET DEFAULT nextval('public.click_conversion_log_details_id_seq'::regclass);


--
-- TOC entry 5143 (class 2604 OID 96058)
-- Name: click_conversion_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_logs ALTER COLUMN id SET DEFAULT nextval('public.click_conversion_logs_id_seq'::regclass);


--
-- TOC entry 5146 (class 2604 OID 96059)
-- Name: click_conversion_pixels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_pixels ALTER COLUMN id SET DEFAULT nextval('public.click_conversion_pixels_id_seq'::regclass);


--
-- TOC entry 5147 (class 2604 OID 96060)
-- Name: click_conversions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversions ALTER COLUMN id SET DEFAULT nextval('public.click_conversions_id_seq'::regclass);


--
-- TOC entry 5148 (class 2604 OID 96061)
-- Name: click_integration_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_integration_logs ALTER COLUMN id SET DEFAULT nextval('public.click_integration_logs_id_seq'::regclass);


--
-- TOC entry 5149 (class 2604 OID 96062)
-- Name: click_integration_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_integration_types ALTER COLUMN id SET DEFAULT nextval('public.click_integration_types_id_seq'::regclass);


--
-- TOC entry 5150 (class 2604 OID 96063)
-- Name: click_integrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_integrations ALTER COLUMN id SET DEFAULT nextval('public.click_integrations_id_seq'::regclass);


--
-- TOC entry 5151 (class 2604 OID 96064)
-- Name: click_listings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_listings ALTER COLUMN id SET DEFAULT nextval('public.click_listings_id_seq'::regclass);


--
-- TOC entry 5156 (class 2604 OID 96065)
-- Name: click_opportunities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_opportunities ALTER COLUMN id SET DEFAULT nextval('public.click_opportunities_id_seq'::regclass);


--
-- TOC entry 5157 (class 2604 OID 96066)
-- Name: click_panels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_panels ALTER COLUMN id SET DEFAULT nextval('public.click_panels_id_seq'::regclass);


--
-- TOC entry 5158 (class 2604 OID 96067)
-- Name: click_ping_debug_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_debug_logs ALTER COLUMN id SET DEFAULT nextval('public.click_ping_debug_logs_id_seq'::regclass);


--
-- TOC entry 5159 (class 2604 OID 96068)
-- Name: click_ping_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_details ALTER COLUMN id SET DEFAULT nextval('public.click_ping_details_id_seq'::regclass);


--
-- TOC entry 5160 (class 2604 OID 96069)
-- Name: click_ping_matches id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_matches ALTER COLUMN id SET DEFAULT nextval('public.click_ping_matches_id_seq'::regclass);


--
-- TOC entry 5161 (class 2604 OID 96070)
-- Name: click_ping_vals id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_vals ALTER COLUMN id SET DEFAULT nextval('public.click_ping_vals_id_seq'::regclass);


--
-- TOC entry 5162 (class 2604 OID 96071)
-- Name: click_pings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_pings ALTER COLUMN id SET DEFAULT nextval('public.click_pings_id_seq'::regclass);


--
-- TOC entry 5163 (class 2604 OID 96072)
-- Name: click_posts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_posts ALTER COLUMN id SET DEFAULT nextval('public.click_posts_id_seq'::regclass);


--
-- TOC entry 5164 (class 2604 OID 96073)
-- Name: click_receipts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_receipts ALTER COLUMN id SET DEFAULT nextval('public.click_receipts_id_seq'::regclass);


--
-- TOC entry 5165 (class 2604 OID 96074)
-- Name: click_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_results ALTER COLUMN id SET DEFAULT nextval('public.click_results_id_seq'::regclass);


--
-- TOC entry 5166 (class 2604 OID 96075)
-- Name: clicks_dashboard_customize_column_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clicks_dashboard_customize_column_orders ALTER COLUMN id SET DEFAULT nextval('public.clicks_dashboard_customize_column_orders_id_seq'::regclass);


--
-- TOC entry 5211 (class 2604 OID 96076)
-- Name: close_com_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.close_com_items ALTER COLUMN id SET DEFAULT nextval('public.close_com_items_id_seq'::regclass);


--
-- TOC entry 5212 (class 2604 OID 96077)
-- Name: conversion_log_transactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversion_log_transactions ALTER COLUMN id SET DEFAULT nextval('public.conversion_log_transactions_id_seq'::regclass);


--
-- TOC entry 5213 (class 2604 OID 96078)
-- Name: conversions_logs_pixel_cols id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversions_logs_pixel_cols ALTER COLUMN id SET DEFAULT nextval('public.conversions_logs_pixel_cols_id_seq'::regclass);


--
-- TOC entry 5217 (class 2604 OID 96079)
-- Name: custom_intermediate_integration_configs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_intermediate_integration_configs ALTER COLUMN id SET DEFAULT nextval('public.custom_intermediate_integration_configs_id_seq'::regclass);


--
-- TOC entry 5218 (class 2604 OID 96080)
-- Name: customize_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customize_orders ALTER COLUMN id SET DEFAULT nextval('public.customize_orders_id_seq'::regclass);


--
-- TOC entry 5219 (class 2604 OID 96081)
-- Name: days id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days ALTER COLUMN id SET DEFAULT nextval('public.days_id_seq'::regclass);


--
-- TOC entry 5220 (class 2604 OID 96082)
-- Name: dms_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dms_logs ALTER COLUMN id SET DEFAULT nextval('public.dms_logs_id_seq'::regclass);


--
-- TOC entry 5222 (class 2604 OID 96083)
-- Name: email_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_events ALTER COLUMN id SET DEFAULT nextval('public.email_events_id_seq'::regclass);


--
-- TOC entry 5223 (class 2604 OID 96084)
-- Name: email_export_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_export_logs ALTER COLUMN id SET DEFAULT nextval('public.email_export_logs_id_seq'::regclass);


--
-- TOC entry 5224 (class 2604 OID 96085)
-- Name: email_template_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_template_logs ALTER COLUMN id SET DEFAULT nextval('public.email_template_logs_id_seq'::regclass);


--
-- TOC entry 5225 (class 2604 OID 96086)
-- Name: farmers_skus id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_skus ALTER COLUMN id SET DEFAULT nextval('public.farmers_skus_id_seq'::regclass);


--
-- TOC entry 5228 (class 2604 OID 96087)
-- Name: features id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.features ALTER COLUMN id SET DEFAULT nextval('public.features_id_seq'::regclass);


--
-- TOC entry 5233 (class 2604 OID 96088)
-- Name: filter_package_filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filter_package_filters ALTER COLUMN id SET DEFAULT nextval('public.filter_package_filters_id_seq'::regclass);


--
-- TOC entry 5236 (class 2604 OID 96089)
-- Name: filter_packages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filter_packages ALTER COLUMN id SET DEFAULT nextval('public.filter_packages_id_seq'::regclass);


--
-- TOC entry 5239 (class 2604 OID 96090)
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- TOC entry 5240 (class 2604 OID 96091)
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- TOC entry 5241 (class 2604 OID 96092)
-- Name: history_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history_versions ALTER COLUMN id SET DEFAULT nextval('public.history_versions_id_seq'::regclass);


--
-- TOC entry 5242 (class 2604 OID 96093)
-- Name: insurance_carriers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insurance_carriers ALTER COLUMN id SET DEFAULT nextval('public.insurance_carriers_id_seq'::regclass);


--
-- TOC entry 5243 (class 2604 OID 96094)
-- Name: intermediate_lead_integrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intermediate_lead_integrations ALTER COLUMN id SET DEFAULT nextval('public.intermediate_lead_integrations_id_seq'::regclass);


--
-- TOC entry 5244 (class 2604 OID 96095)
-- Name: internal_api_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_api_tokens ALTER COLUMN id SET DEFAULT nextval('public.internal_api_tokens_id_seq'::regclass);


--
-- TOC entry 5245 (class 2604 OID 96096)
-- Name: invoice_raw_stats id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_raw_stats ALTER COLUMN id SET DEFAULT nextval('public.invoice_raw_stats_id_seq'::regclass);


--
-- TOC entry 5246 (class 2604 OID 96097)
-- Name: invoices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices ALTER COLUMN id SET DEFAULT nextval('public.invoices_id_seq'::regclass);


--
-- TOC entry 5248 (class 2604 OID 96098)
-- Name: jira_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jira_users ALTER COLUMN id SET DEFAULT nextval('public.jira_users_id_seq'::regclass);


--
-- TOC entry 5249 (class 2604 OID 96099)
-- Name: jwt_denylist id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jwt_denylist ALTER COLUMN id SET DEFAULT nextval('public.jwt_denylist_id_seq'::regclass);


--
-- TOC entry 5250 (class 2604 OID 96100)
-- Name: lead_applicants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_applicants ALTER COLUMN id SET DEFAULT nextval('public.lead_applicants_id_seq'::regclass);


--
-- TOC entry 5254 (class 2604 OID 96101)
-- Name: lead_business_entities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_business_entities ALTER COLUMN id SET DEFAULT nextval('public.lead_business_entities_id_seq'::regclass);


--
-- TOC entry 5256 (class 2604 OID 96102)
-- Name: lead_campaign_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_campaign_settings ALTER COLUMN id SET DEFAULT nextval('public.lead_campaign_settings_id_seq'::regclass);


--
-- TOC entry 5263 (class 2604 OID 96103)
-- Name: lead_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_details ALTER COLUMN id SET DEFAULT nextval('public.lead_details_id_seq'::regclass);


--
-- TOC entry 5264 (class 2604 OID 96104)
-- Name: lead_homes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_homes ALTER COLUMN id SET DEFAULT nextval('public.lead_homes_id_seq'::regclass);


--
-- TOC entry 5265 (class 2604 OID 96105)
-- Name: lead_integration_failure_reasons id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_failure_reasons ALTER COLUMN id SET DEFAULT nextval('public.lead_integration_failure_reasons_id_seq'::regclass);


--
-- TOC entry 5266 (class 2604 OID 96106)
-- Name: lead_integration_macro_mappings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_macro_mappings ALTER COLUMN id SET DEFAULT nextval('public.lead_integration_macro_mappings_id_seq'::regclass);


--
-- TOC entry 5267 (class 2604 OID 96107)
-- Name: lead_integration_macros id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_macros ALTER COLUMN id SET DEFAULT nextval('public.lead_integration_macros_id_seq'::regclass);


--
-- TOC entry 5268 (class 2604 OID 96108)
-- Name: lead_integration_req_headers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_headers ALTER COLUMN id SET DEFAULT nextval('public.lead_integration_req_headers_id_seq'::regclass);


--
-- TOC entry 5269 (class 2604 OID 96109)
-- Name: lead_integration_req_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_logs ALTER COLUMN id SET DEFAULT nextval('public.lead_integration_req_logs_id_seq'::regclass);


--
-- TOC entry 5270 (class 2604 OID 96110)
-- Name: lead_integration_req_payloads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_payloads ALTER COLUMN id SET DEFAULT nextval('public.lead_integration_req_payloads_id_seq'::regclass);


--
-- TOC entry 5271 (class 2604 OID 96111)
-- Name: lead_integrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integrations ALTER COLUMN id SET DEFAULT nextval('public.lead_integrations_id_seq'::regclass);


--
-- TOC entry 5280 (class 2604 OID 96112)
-- Name: lead_listings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_listings ALTER COLUMN id SET DEFAULT nextval('public.lead_listings_id_seq'::regclass);


--
-- TOC entry 5282 (class 2604 OID 96113)
-- Name: lead_opportunities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_opportunities ALTER COLUMN id SET DEFAULT nextval('public.lead_opportunities_id_seq'::regclass);


--
-- TOC entry 5283 (class 2604 OID 96114)
-- Name: lead_ping_debug_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_ping_debug_logs ALTER COLUMN id SET DEFAULT nextval('public.lead_ping_debug_logs_id_seq'::regclass);


--
-- TOC entry 5284 (class 2604 OID 96115)
-- Name: lead_ping_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_ping_details ALTER COLUMN id SET DEFAULT nextval('public.lead_ping_details_id_seq'::regclass);


--
-- TOC entry 5285 (class 2604 OID 96116)
-- Name: lead_ping_matches id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_ping_matches ALTER COLUMN id SET DEFAULT nextval('public.lead_ping_matches_id_seq'::regclass);


--
-- TOC entry 5286 (class 2604 OID 96117)
-- Name: lead_pings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_pings ALTER COLUMN id SET DEFAULT nextval('public.lead_pings_id_seq'::regclass);


--
-- TOC entry 5287 (class 2604 OID 96118)
-- Name: lead_post_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_post_details ALTER COLUMN id SET DEFAULT nextval('public.lead_post_details_id_seq'::regclass);


--
-- TOC entry 5288 (class 2604 OID 96119)
-- Name: lead_post_legs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_post_legs ALTER COLUMN id SET DEFAULT nextval('public.lead_post_legs_id_seq'::regclass);


--
-- TOC entry 5289 (class 2604 OID 96120)
-- Name: lead_posts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_posts ALTER COLUMN id SET DEFAULT nextval('public.lead_posts_id_seq'::regclass);


--
-- TOC entry 5290 (class 2604 OID 96121)
-- Name: lead_prices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_prices ALTER COLUMN id SET DEFAULT nextval('public.lead_prices_id_seq'::regclass);


--
-- TOC entry 5292 (class 2604 OID 96122)
-- Name: lead_refund_reasons id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_refund_reasons ALTER COLUMN id SET DEFAULT nextval('public.lead_refund_reasons_id_seq'::regclass);


--
-- TOC entry 5293 (class 2604 OID 96123)
-- Name: lead_refunds id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_refunds ALTER COLUMN id SET DEFAULT nextval('public.lead_refunds_id_seq'::regclass);


--
-- TOC entry 5294 (class 2604 OID 96124)
-- Name: lead_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_types ALTER COLUMN id SET DEFAULT nextval('public.lead_types_id_seq'::regclass);


--
-- TOC entry 5295 (class 2604 OID 96125)
-- Name: lead_vehicles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_vehicles ALTER COLUMN id SET DEFAULT nextval('public.lead_vehicles_id_seq'::regclass);


--
-- TOC entry 5297 (class 2604 OID 96126)
-- Name: lead_violations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_violations ALTER COLUMN id SET DEFAULT nextval('public.lead_violations_id_seq'::regclass);


--
-- TOC entry 5298 (class 2604 OID 96127)
-- Name: leads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads ALTER COLUMN id SET DEFAULT nextval('public.leads_id_seq'::regclass);


--
-- TOC entry 5299 (class 2604 OID 96128)
-- Name: leads_customize_columns_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads_customize_columns_orders ALTER COLUMN id SET DEFAULT nextval('public.leads_customize_columns_orders_id_seq'::regclass);


--
-- TOC entry 5311 (class 2604 OID 96129)
-- Name: leads_dashboard_customize_column_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads_dashboard_customize_column_orders ALTER COLUMN id SET DEFAULT nextval('public.leads_dashboard_customize_column_orders_id_seq'::regclass);


--
-- TOC entry 5339 (class 2604 OID 96130)
-- Name: memberships id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships ALTER COLUMN id SET DEFAULT nextval('public.memberships_id_seq'::regclass);


--
-- TOC entry 5340 (class 2604 OID 96131)
-- Name: mv_refresh_statuses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mv_refresh_statuses ALTER COLUMN id SET DEFAULT nextval('public.mv_refresh_statuses_id_seq'::regclass);


--
-- TOC entry 5342 (class 2604 OID 96132)
-- Name: non_rtb_ping_stats id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.non_rtb_ping_stats ALTER COLUMN id SET DEFAULT nextval('public.non_rtb_ping_stats_id_seq'::regclass);


--
-- TOC entry 5343 (class 2604 OID 96133)
-- Name: notification_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_events ALTER COLUMN id SET DEFAULT nextval('public.notification_events_id_seq'::regclass);


--
-- TOC entry 5344 (class 2604 OID 96134)
-- Name: notification_job_sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_job_sources ALTER COLUMN id SET DEFAULT nextval('public.notification_job_sources_id_seq'::regclass);


--
-- TOC entry 5345 (class 2604 OID 96135)
-- Name: notification_preferences id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences ALTER COLUMN id SET DEFAULT nextval('public.notification_preferences_id_seq'::regclass);


--
-- TOC entry 5348 (class 2604 OID 96136)
-- Name: old_passwords id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.old_passwords ALTER COLUMN id SET DEFAULT nextval('public.old_passwords_id_seq'::regclass);


--
-- TOC entry 5349 (class 2604 OID 96137)
-- Name: page_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_groups ALTER COLUMN id SET DEFAULT nextval('public.page_groups_id_seq'::regclass);


--
-- TOC entry 5351 (class 2604 OID 96138)
-- Name: pages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pages ALTER COLUMN id SET DEFAULT nextval('public.pages_id_seq'::regclass);


--
-- TOC entry 5352 (class 2604 OID 96139)
-- Name: payment_terms id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_terms ALTER COLUMN id SET DEFAULT nextval('public.payment_terms_id_seq'::regclass);


--
-- TOC entry 5354 (class 2604 OID 96140)
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- TOC entry 5359 (class 2604 OID 96141)
-- Name: platform_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.platform_settings ALTER COLUMN id SET DEFAULT nextval('public.platform_settings_id_seq'::regclass);


--
-- TOC entry 5366 (class 2604 OID 96142)
-- Name: popup_lead_type_messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.popup_lead_type_messages ALTER COLUMN id SET DEFAULT nextval('public.popup_lead_type_messages_id_seq'::regclass);


--
-- TOC entry 5367 (class 2604 OID 96143)
-- Name: postback_url_req_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postback_url_req_logs ALTER COLUMN id SET DEFAULT nextval('public.postback_url_req_logs_id_seq'::regclass);


--
-- TOC entry 5368 (class 2604 OID 96144)
-- Name: pp_ping_report_accounts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pp_ping_report_accounts ALTER COLUMN id SET DEFAULT nextval('public.pp_ping_report_accounts_id_seq'::regclass);


--
-- TOC entry 5369 (class 2604 OID 96145)
-- Name: prefill_queries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prefill_queries ALTER COLUMN id SET DEFAULT nextval('public.prefill_queries_id_seq'::regclass);


--
-- TOC entry 5371 (class 2604 OID 96146)
-- Name: product_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_types ALTER COLUMN id SET DEFAULT nextval('public.product_types_id_seq'::regclass);


--
-- TOC entry 5372 (class 2604 OID 96147)
-- Name: prospects_customize_columns_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prospects_customize_columns_orders ALTER COLUMN id SET DEFAULT nextval('public.prospects_customize_columns_orders_id_seq'::regclass);


--
-- TOC entry 5392 (class 2604 OID 96148)
-- Name: qf_call_integrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_call_integrations ALTER COLUMN id SET DEFAULT nextval('public.qf_call_integrations_id_seq'::regclass);


--
-- TOC entry 5393 (class 2604 OID 96149)
-- Name: qf_call_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_call_settings ALTER COLUMN id SET DEFAULT nextval('public.qf_call_settings_id_seq'::regclass);


--
-- TOC entry 5394 (class 2604 OID 96150)
-- Name: qf_lead_integrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_lead_integrations ALTER COLUMN id SET DEFAULT nextval('public.qf_lead_integrations_id_seq'::regclass);


--
-- TOC entry 5395 (class 2604 OID 96151)
-- Name: qf_lead_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_lead_settings ALTER COLUMN id SET DEFAULT nextval('public.qf_lead_settings_id_seq'::regclass);


--
-- TOC entry 5396 (class 2604 OID 96152)
-- Name: qf_quote_call_qas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_qas ALTER COLUMN id SET DEFAULT nextval('public.qf_quote_call_qas_id_seq'::regclass);


--
-- TOC entry 5397 (class 2604 OID 96153)
-- Name: qf_quote_call_summaries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_summaries ALTER COLUMN id SET DEFAULT nextval('public.qf_quote_call_summaries_id_seq'::regclass);


--
-- TOC entry 5398 (class 2604 OID 96154)
-- Name: qf_quote_call_transcriptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_transcriptions ALTER COLUMN id SET DEFAULT nextval('public.qf_quote_call_transcriptions_id_seq'::regclass);


--
-- TOC entry 5399 (class 2604 OID 96155)
-- Name: qf_quote_calls id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_calls ALTER COLUMN id SET DEFAULT nextval('public.qf_quote_calls_id_seq'::regclass);


--
-- TOC entry 5401 (class 2604 OID 96156)
-- Name: question_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.question_groups ALTER COLUMN id SET DEFAULT nextval('public.question_groups_id_seq'::regclass);


--
-- TOC entry 5403 (class 2604 OID 96157)
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- TOC entry 5407 (class 2604 OID 96158)
-- Name: quote_call_qas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_qas ALTER COLUMN id SET DEFAULT nextval('public.quote_call_qas_id_seq'::regclass);


--
-- TOC entry 5408 (class 2604 OID 96159)
-- Name: quote_call_summaries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_summaries ALTER COLUMN id SET DEFAULT nextval('public.quote_call_summaries_id_seq'::regclass);


--
-- TOC entry 5409 (class 2604 OID 96160)
-- Name: quote_call_transcriptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_transcriptions ALTER COLUMN id SET DEFAULT nextval('public.quote_call_transcriptions_id_seq'::regclass);


--
-- TOC entry 5410 (class 2604 OID 96161)
-- Name: quote_calls id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_calls ALTER COLUMN id SET DEFAULT nextval('public.quote_calls_id_seq'::regclass);


--
-- TOC entry 5412 (class 2604 OID 96162)
-- Name: quote_form_visits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_form_visits ALTER COLUMN id SET DEFAULT nextval('public.quote_form_visits_id_seq'::regclass);


--
-- TOC entry 5414 (class 2604 OID 96163)
-- Name: quote_funnels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_funnels ALTER COLUMN id SET DEFAULT nextval('public.quote_funnels_id_seq'::regclass);


--
-- TOC entry 5417 (class 2604 OID 96164)
-- Name: quote_funnels_prices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_funnels_prices ALTER COLUMN id SET DEFAULT nextval('public.quote_funnels_prices_id_seq'::regclass);


--
-- TOC entry 5418 (class 2604 OID 96165)
-- Name: rds_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rds_logs ALTER COLUMN id SET DEFAULT nextval('public.rds_logs_id_seq'::regclass);


--
-- TOC entry 5420 (class 2604 OID 96166)
-- Name: receipt_transaction_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipt_transaction_types ALTER COLUMN id SET DEFAULT nextval('public.receipt_transaction_types_id_seq'::regclass);


--
-- TOC entry 5422 (class 2604 OID 96167)
-- Name: receipt_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipt_types ALTER COLUMN id SET DEFAULT nextval('public.receipt_types_id_seq'::regclass);


--
-- TOC entry 5423 (class 2604 OID 96168)
-- Name: receipts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipts ALTER COLUMN id SET DEFAULT nextval('public.receipts_id_seq'::regclass);


--
-- TOC entry 5429 (class 2604 OID 96169)
-- Name: recently_visited_client_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recently_visited_client_users ALTER COLUMN id SET DEFAULT nextval('public.recently_visited_client_users_id_seq'::regclass);


--
-- TOC entry 5430 (class 2604 OID 96170)
-- Name: registration_pending_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_pending_users ALTER COLUMN id SET DEFAULT nextval('public.registration_pending_users_id_seq'::regclass);


--
-- TOC entry 5433 (class 2604 OID 96171)
-- Name: response_parser_functions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.response_parser_functions ALTER COLUMN id SET DEFAULT nextval('public.response_parser_functions_id_seq'::regclass);


--
-- TOC entry 5434 (class 2604 OID 96172)
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- TOC entry 5435 (class 2604 OID 96173)
-- Name: rtb_bids id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rtb_bids ALTER COLUMN id SET DEFAULT nextval('public.rtb_bids_id_seq'::regclass);


--
-- TOC entry 5436 (class 2604 OID 96174)
-- Name: rule_validator_checks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rule_validator_checks ALTER COLUMN id SET DEFAULT nextval('public.rule_validator_checks_id_seq'::regclass);


--
-- TOC entry 5439 (class 2604 OID 96175)
-- Name: sample_leads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sample_leads ALTER COLUMN id SET DEFAULT nextval('public.sample_leads_id_seq'::regclass);


--
-- TOC entry 5440 (class 2604 OID 96176)
-- Name: scheduled_report_emails id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_emails ALTER COLUMN id SET DEFAULT nextval('public.scheduled_report_emails_id_seq'::regclass);


--
-- TOC entry 5441 (class 2604 OID 96177)
-- Name: scheduled_report_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_logs ALTER COLUMN id SET DEFAULT nextval('public.scheduled_report_logs_id_seq'::regclass);


--
-- TOC entry 5442 (class 2604 OID 96178)
-- Name: scheduled_report_sftps id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_sftps ALTER COLUMN id SET DEFAULT nextval('public.scheduled_report_sftps_id_seq'::regclass);


--
-- TOC entry 5443 (class 2604 OID 96179)
-- Name: scheduled_report_uploads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_uploads ALTER COLUMN id SET DEFAULT nextval('public.scheduled_report_uploads_id_seq'::regclass);


--
-- TOC entry 5444 (class 2604 OID 96180)
-- Name: scheduled_reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_reports ALTER COLUMN id SET DEFAULT nextval('public.scheduled_reports_id_seq'::regclass);


--
-- TOC entry 5446 (class 2604 OID 96181)
-- Name: semaphore_deployments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semaphore_deployments ALTER COLUMN id SET DEFAULT nextval('public.semaphore_deployments_id_seq'::regclass);


--
-- TOC entry 5448 (class 2604 OID 96182)
-- Name: sf_filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_filters ALTER COLUMN id SET DEFAULT nextval('public.sf_filters_id_seq'::regclass);


--
-- TOC entry 5456 (class 2604 OID 96183)
-- Name: sf_lead_integration_macro_categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macro_categories ALTER COLUMN id SET DEFAULT nextval('public.sf_lead_integration_macro_categories_id_seq'::regclass);


--
-- TOC entry 5457 (class 2604 OID 96184)
-- Name: sf_lead_integration_macro_lead_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macro_lead_types ALTER COLUMN id SET DEFAULT nextval('public.sf_lead_integration_macro_lead_types_id_seq'::regclass);


--
-- TOC entry 5458 (class 2604 OID 96185)
-- Name: sf_lead_integration_macros id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macros ALTER COLUMN id SET DEFAULT nextval('public.sf_lead_integration_macros_id_seq'::regclass);


--
-- TOC entry 5461 (class 2604 OID 96186)
-- Name: sf_smart_views id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_smart_views ALTER COLUMN id SET DEFAULT nextval('public.sf_smart_views_id_seq'::regclass);


--
-- TOC entry 5465 (class 2604 OID 96187)
-- Name: sidekiq_job_error_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sidekiq_job_error_logs ALTER COLUMN id SET DEFAULT nextval('public.sidekiq_job_error_logs_id_seq'::regclass);


--
-- TOC entry 5466 (class 2604 OID 96188)
-- Name: slack_support_channel_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slack_support_channel_requests ALTER COLUMN id SET DEFAULT nextval('public.slack_support_channel_requests_id_seq'::regclass);


--
-- TOC entry 5467 (class 2604 OID 96189)
-- Name: slow_query_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slow_query_logs ALTER COLUMN id SET DEFAULT nextval('public.slow_query_logs_id_seq'::regclass);


--
-- TOC entry 5469 (class 2604 OID 96190)
-- Name: source_pixel_columns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_pixel_columns ALTER COLUMN id SET DEFAULT nextval('public.source_pixel_columns_id_seq'::regclass);


--
-- TOC entry 5478 (class 2604 OID 96191)
-- Name: source_setting_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_setting_notes ALTER COLUMN id SET DEFAULT nextval('public.source_setting_notes_id_seq'::regclass);


--
-- TOC entry 5479 (class 2604 OID 96192)
-- Name: source_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_types ALTER COLUMN id SET DEFAULT nextval('public.source_types_id_seq'::regclass);


--
-- TOC entry 5482 (class 2604 OID 96193)
-- Name: state_names id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.state_names ALTER COLUMN id SET DEFAULT nextval('public.state_names_id_seq'::regclass);


--
-- TOC entry 5483 (class 2604 OID 96194)
-- Name: syndi_click_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.syndi_click_rules ALTER COLUMN id SET DEFAULT nextval('public.syndi_click_rules_id_seq'::regclass);


--
-- TOC entry 5484 (class 2604 OID 96195)
-- Name: syndi_click_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.syndi_click_settings ALTER COLUMN id SET DEFAULT nextval('public.syndi_click_settings_id_seq'::regclass);


--
-- TOC entry 5486 (class 2604 OID 96196)
-- Name: template_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_assignments ALTER COLUMN id SET DEFAULT nextval('public.template_assignments_id_seq'::regclass);


--
-- TOC entry 5487 (class 2604 OID 96197)
-- Name: terms_of_services id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terms_of_services ALTER COLUMN id SET DEFAULT nextval('public.terms_of_services_id_seq'::regclass);


--
-- TOC entry 5488 (class 2604 OID 96198)
-- Name: trusted_form_certificates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trusted_form_certificates ALTER COLUMN id SET DEFAULT nextval('public.trusted_form_certificates_id_seq'::regclass);


--
-- TOC entry 5489 (class 2604 OID 96199)
-- Name: twilio_phone_numbers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_phone_numbers ALTER COLUMN id SET DEFAULT nextval('public.twilio_phone_numbers_id_seq'::regclass);


--
-- TOC entry 5491 (class 2604 OID 96200)
-- Name: user_activity_customize_columns_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_activity_customize_columns_orders ALTER COLUMN id SET DEFAULT nextval('public.user_activity_customize_columns_orders_id_seq'::regclass);


--
-- TOC entry 5519 (class 2604 OID 96201)
-- Name: user_col_pref_admin_dashboards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_admin_dashboards ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_admin_dashboards_id_seq'::regclass);


--
-- TOC entry 5543 (class 2604 OID 96202)
-- Name: user_col_pref_analytics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_analytics ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_analytics_id_seq'::regclass);


--
-- TOC entry 5693 (class 2604 OID 96203)
-- Name: user_col_pref_calls_dashboard_campaigns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_calls_dashboard_campaigns ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_calls_dashboard_campaigns_id_seq'::regclass);


--
-- TOC entry 5702 (class 2604 OID 96204)
-- Name: user_col_pref_calls_dashboard_states id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_calls_dashboard_states ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_calls_dashboard_states_id_seq'::regclass);


--
-- TOC entry 5719 (class 2604 OID 96205)
-- Name: user_col_pref_clicks_dashboards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_clicks_dashboards ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_clicks_dashboards_id_seq'::regclass);


--
-- TOC entry 5764 (class 2604 OID 96206)
-- Name: user_col_pref_conversion_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_conversion_logs ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_conversion_logs_id_seq'::regclass);


--
-- TOC entry 5772 (class 2604 OID 96207)
-- Name: user_col_pref_leads_dashboards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_leads_dashboards ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_leads_dashboards_id_seq'::regclass);


--
-- TOC entry 5800 (class 2604 OID 96208)
-- Name: user_col_pref_syndi_clicks_dashboards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_syndi_clicks_dashboards ALTER COLUMN id SET DEFAULT nextval('public.user_col_pref_syndi_clicks_dashboards_id_seq'::regclass);


--
-- TOC entry 5843 (class 2604 OID 96209)
-- Name: user_column_preference_ad_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_ad_groups ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_ad_groups_id_seq'::regclass);


--
-- TOC entry 5872 (class 2604 OID 96210)
-- Name: user_column_preference_call_profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_call_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_call_profiles_id_seq'::regclass);


--
-- TOC entry 5898 (class 2604 OID 96211)
-- Name: user_column_preference_call_source_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_call_source_settings ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_call_source_settings_id_seq'::regclass);


--
-- TOC entry 5923 (class 2604 OID 96212)
-- Name: user_column_preference_calls id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_calls ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_calls_id_seq'::regclass);


--
-- TOC entry 5947 (class 2604 OID 96213)
-- Name: user_column_preference_campaigns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_campaigns ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_campaigns_id_seq'::regclass);


--
-- TOC entry 6021 (class 2604 OID 96214)
-- Name: user_column_preference_lead_profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_lead_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_lead_profiles_id_seq'::regclass);


--
-- TOC entry 6044 (class 2604 OID 96215)
-- Name: user_column_preference_lead_source_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_lead_source_settings ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_lead_source_settings_id_seq'::regclass);


--
-- TOC entry 6066 (class 2604 OID 96216)
-- Name: user_column_preference_leads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_leads ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_leads_id_seq'::regclass);


--
-- TOC entry 6078 (class 2604 OID 96217)
-- Name: user_column_preference_prospects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_prospects ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_prospects_id_seq'::regclass);


--
-- TOC entry 6098 (class 2604 OID 96218)
-- Name: user_column_preference_source_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_source_settings ALTER COLUMN id SET DEFAULT nextval('public.user_column_preference_source_settings_id_seq'::regclass);


--
-- TOC entry 6126 (class 2604 OID 96219)
-- Name: user_notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications ALTER COLUMN id SET DEFAULT nextval('public.user_notifications_id_seq'::regclass);


--
-- TOC entry 6127 (class 2604 OID 96220)
-- Name: user_smart_views id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_smart_views ALTER COLUMN id SET DEFAULT nextval('public.user_smart_views_id_seq'::regclass);


--
-- TOC entry 6132 (class 2604 OID 96221)
-- Name: user_terms_of_services id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_terms_of_services ALTER COLUMN id SET DEFAULT nextval('public.user_terms_of_services_id_seq'::regclass);


--
-- TOC entry 6133 (class 2604 OID 96222)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 6139 (class 2604 OID 96223)
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- TOC entry 6140 (class 2604 OID 96224)
-- Name: violation_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.violation_types ALTER COLUMN id SET DEFAULT nextval('public.violation_types_id_seq'::regclass);


--
-- TOC entry 6141 (class 2604 OID 96225)
-- Name: white_listing_brands id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.white_listing_brands ALTER COLUMN id SET DEFAULT nextval('public.white_listing_brands_id_seq'::regclass);


--
-- TOC entry 6142 (class 2604 OID 96226)
-- Name: whitelabeled_brands_user_login_mappings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelabeled_brands_user_login_mappings ALTER COLUMN id SET DEFAULT nextval('public.whitelabeled_brands_user_login_mappings_id_seq'::regclass);


--
-- TOC entry 6143 (class 2604 OID 96227)
-- Name: whitelisting_brand_admin_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelisting_brand_admin_assignments ALTER COLUMN id SET DEFAULT nextval('public.whitelisting_brand_admin_assignments_id_seq'::regclass);


--
-- TOC entry 6144 (class 2604 OID 96228)
-- Name: zip_tier_locations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zip_tier_locations ALTER COLUMN id SET DEFAULT nextval('public.zip_tier_locations_id_seq'::regclass);


--
-- TOC entry 6145 (class 2604 OID 96229)
-- Name: zip_tiers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zip_tiers ALTER COLUMN id SET DEFAULT nextval('public.zip_tiers_id_seq'::regclass);


--
-- TOC entry 6146 (class 2604 OID 96230)
-- Name: zipcodes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zipcodes ALTER COLUMN id SET DEFAULT nextval('public.zipcodes_id_seq'::regclass);


--
-- TOC entry 6148 (class 2606 OID 96232)
-- Name: access_tokens access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 6150 (class 2606 OID 96234)
-- Name: access_tokens access_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_token_key UNIQUE (token);


--
-- TOC entry 6152 (class 2606 OID 96236)
-- Name: account_balances account_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_balances
    ADD CONSTRAINT account_balances_pkey PRIMARY KEY (id);


--
-- TOC entry 6155 (class 2606 OID 96238)
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- TOC entry 6160 (class 2606 OID 96240)
-- Name: ad_contents ad_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_contents
    ADD CONSTRAINT ad_contents_pkey PRIMARY KEY (id);


--
-- TOC entry 6164 (class 2606 OID 96242)
-- Name: ad_group_ads ad_group_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_ads
    ADD CONSTRAINT ad_group_ads_pkey PRIMARY KEY (id);


--
-- TOC entry 6169 (class 2606 OID 96244)
-- Name: ad_group_filter_groups ad_group_filter_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filter_groups
    ADD CONSTRAINT ad_group_filter_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 6173 (class 2606 OID 96246)
-- Name: ad_group_filters ad_group_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filters
    ADD CONSTRAINT ad_group_filters_pkey PRIMARY KEY (id);


--
-- TOC entry 6179 (class 2606 OID 96248)
-- Name: ad_group_locations ad_group_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_locations
    ADD CONSTRAINT ad_group_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 6186 (class 2606 OID 96250)
-- Name: ad_group_notes ad_group_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_notes
    ADD CONSTRAINT ad_group_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 6191 (class 2606 OID 96252)
-- Name: ad_group_pixel_columns ad_group_pixel_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_pixel_columns
    ADD CONSTRAINT ad_group_pixel_columns_pkey PRIMARY KEY (id);


--
-- TOC entry 6194 (class 2606 OID 96254)
-- Name: ad_groups ad_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_groups
    ADD CONSTRAINT ad_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 6199 (class 2606 OID 96256)
-- Name: admin_assignments admin_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_assignments
    ADD CONSTRAINT admin_assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 6204 (class 2606 OID 96258)
-- Name: admin_clients_customize_columns_orders admin_clients_customize_columns_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_clients_customize_columns_orders
    ADD CONSTRAINT admin_clients_customize_columns_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6207 (class 2606 OID 96260)
-- Name: admin_features admin_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_features
    ADD CONSTRAINT admin_features_pkey PRIMARY KEY (id);


--
-- TOC entry 6210 (class 2606 OID 96262)
-- Name: admin_notification_template_types admin_notification_template_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_template_types
    ADD CONSTRAINT admin_notification_template_types_pkey PRIMARY KEY (id);


--
-- TOC entry 6215 (class 2606 OID 96264)
-- Name: admin_notification_templates admin_notification_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_templates
    ADD CONSTRAINT admin_notification_templates_pkey PRIMARY KEY (id);


--
-- TOC entry 6218 (class 2606 OID 96266)
-- Name: admin_notification_types admin_notification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_types
    ADD CONSTRAINT admin_notification_types_pkey PRIMARY KEY (id);


--
-- TOC entry 6220 (class 2606 OID 96268)
-- Name: admin_permissions admin_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 6224 (class 2606 OID 96270)
-- Name: admin_roles admin_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_roles
    ADD CONSTRAINT admin_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 6228 (class 2606 OID 96272)
-- Name: admin_slack_notification_logs admin_slack_notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_slack_notification_logs
    ADD CONSTRAINT admin_slack_notification_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6231 (class 2606 OID 96274)
-- Name: admin_user_col_pref_user_activities admin_user_col_pref_user_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_col_pref_user_activities
    ADD CONSTRAINT admin_user_col_pref_user_activities_pkey PRIMARY KEY (id);


--
-- TOC entry 6234 (class 2606 OID 96276)
-- Name: admin_user_column_preferences admin_user_column_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_column_preferences
    ADD CONSTRAINT admin_user_column_preferences_pkey PRIMARY KEY (id);


--
-- TOC entry 6237 (class 2606 OID 96278)
-- Name: admin_user_customize_column_orders admin_user_customize_column_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_customize_column_orders
    ADD CONSTRAINT admin_user_customize_column_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6240 (class 2606 OID 96280)
-- Name: admin_user_notifications_preferences admin_user_notifications_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_notifications_preferences
    ADD CONSTRAINT admin_user_notifications_preferences_pkey PRIMARY KEY (id);


--
-- TOC entry 6244 (class 2606 OID 96282)
-- Name: admin_user_smart_views admin_user_smart_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_smart_views
    ADD CONSTRAINT admin_user_smart_views_pkey PRIMARY KEY (id);


--
-- TOC entry 6248 (class 2606 OID 96284)
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- TOC entry 6256 (class 2606 OID 96286)
-- Name: ads ads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- TOC entry 6261 (class 2606 OID 96288)
-- Name: agent_profiles agent_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_profiles
    ADD CONSTRAINT agent_profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 6265 (class 2606 OID 96290)
-- Name: ahoy_events ahoy_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ahoy_events
    ADD CONSTRAINT ahoy_events_pkey PRIMARY KEY (id);


--
-- TOC entry 6272 (class 2606 OID 96292)
-- Name: ahoy_visits ahoy_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ahoy_visits
    ADD CONSTRAINT ahoy_visits_pkey PRIMARY KEY (id);


--
-- TOC entry 6276 (class 2606 OID 96294)
-- Name: analytic_pixel_columns analytic_pixel_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytic_pixel_columns
    ADD CONSTRAINT analytic_pixel_columns_pkey PRIMARY KEY (id);


--
-- TOC entry 6279 (class 2606 OID 96296)
-- Name: analytics_export_uploads analytics_export_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_export_uploads
    ADD CONSTRAINT analytics_export_uploads_pkey PRIMARY KEY (id);


--
-- TOC entry 6282 (class 2606 OID 96298)
-- Name: analytics_exports analytics_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_exports
    ADD CONSTRAINT analytics_exports_pkey PRIMARY KEY (id);


--
-- TOC entry 6288 (class 2606 OID 96300)
-- Name: api_profiling_tags api_profiling_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_profiling_tags
    ADD CONSTRAINT api_profiling_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 6290 (class 2606 OID 96302)
-- Name: api_timing_api_profiling_tags api_timing_api_profiling_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_timing_api_profiling_tags
    ADD CONSTRAINT api_timing_api_profiling_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 6294 (class 2606 OID 96304)
-- Name: api_timings api_timings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_timings
    ADD CONSTRAINT api_timings_pkey PRIMARY KEY (id);


--
-- TOC entry 6299 (class 2606 OID 96306)
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- TOC entry 6301 (class 2606 OID 96308)
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 6306 (class 2606 OID 96310)
-- Name: automation_test_execution_results automation_test_execution_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_test_execution_results
    ADD CONSTRAINT automation_test_execution_results_pkey PRIMARY KEY (id);


--
-- TOC entry 6310 (class 2606 OID 96312)
-- Name: automation_test_suite_results automation_test_suite_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_test_suite_results
    ADD CONSTRAINT automation_test_suite_results_pkey PRIMARY KEY (id);


--
-- TOC entry 6314 (class 2606 OID 96314)
-- Name: bill_com_invoices bill_com_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_invoices
    ADD CONSTRAINT bill_com_invoices_pkey PRIMARY KEY (id);


--
-- TOC entry 6322 (class 2606 OID 96316)
-- Name: bill_com_items bill_com_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_items
    ADD CONSTRAINT bill_com_items_pkey PRIMARY KEY (id);


--
-- TOC entry 6324 (class 2606 OID 96318)
-- Name: bill_com_sessions bill_com_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_sessions
    ADD CONSTRAINT bill_com_sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 6326 (class 2606 OID 96320)
-- Name: billing_setting_invoice_changes billing_setting_invoice_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_setting_invoice_changes
    ADD CONSTRAINT billing_setting_invoice_changes_pkey PRIMARY KEY (id);


--
-- TOC entry 6330 (class 2606 OID 96322)
-- Name: billing_settings billing_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_settings
    ADD CONSTRAINT billing_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6333 (class 2606 OID 96324)
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- TOC entry 6337 (class 2606 OID 96326)
-- Name: call_ad_group_settings call_ad_group_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ad_group_settings
    ADD CONSTRAINT call_ad_group_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6341 (class 2606 OID 96328)
-- Name: call_campaign_settings call_campaign_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_campaign_settings
    ADD CONSTRAINT call_campaign_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6347 (class 2606 OID 96330)
-- Name: call_listings call_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_listings
    ADD CONSTRAINT call_listings_pkey PRIMARY KEY (id);


--
-- TOC entry 6356 (class 2606 OID 96332)
-- Name: call_opportunities call_opportunities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_opportunities
    ADD CONSTRAINT call_opportunities_pkey PRIMARY KEY (id);


--
-- TOC entry 6361 (class 2606 OID 96334)
-- Name: call_panels call_panels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_panels
    ADD CONSTRAINT call_panels_pkey PRIMARY KEY (id);


--
-- TOC entry 6364 (class 2606 OID 96336)
-- Name: call_ping_debug_logs call_ping_debug_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ping_debug_logs
    ADD CONSTRAINT call_ping_debug_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6367 (class 2606 OID 96338)
-- Name: call_ping_details call_ping_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ping_details
    ADD CONSTRAINT call_ping_details_pkey PRIMARY KEY (id);


--
-- TOC entry 6370 (class 2606 OID 96340)
-- Name: call_ping_matches call_ping_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ping_matches
    ADD CONSTRAINT call_ping_matches_pkey PRIMARY KEY (id);


--
-- TOC entry 6377 (class 2606 OID 96342)
-- Name: call_pings call_pings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_pings
    ADD CONSTRAINT call_pings_pkey PRIMARY KEY (id);


--
-- TOC entry 6382 (class 2606 OID 96344)
-- Name: call_post_details call_post_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_post_details
    ADD CONSTRAINT call_post_details_pkey PRIMARY KEY (id);


--
-- TOC entry 6387 (class 2606 OID 96346)
-- Name: call_posts call_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_posts
    ADD CONSTRAINT call_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 6390 (class 2606 OID 96348)
-- Name: call_prices call_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_prices
    ADD CONSTRAINT call_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 6393 (class 2606 OID 96350)
-- Name: call_results call_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_results
    ADD CONSTRAINT call_results_pkey PRIMARY KEY (id);


--
-- TOC entry 6398 (class 2606 OID 96352)
-- Name: call_transcription_rules call_transcription_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_rules
    ADD CONSTRAINT call_transcription_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 6402 (class 2606 OID 96354)
-- Name: call_transcription_settings call_transcription_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_settings
    ADD CONSTRAINT call_transcription_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6405 (class 2606 OID 96356)
-- Name: call_transcription_topics call_transcription_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_topics
    ADD CONSTRAINT call_transcription_topics_pkey PRIMARY KEY (id);


--
-- TOC entry 6409 (class 2606 OID 96358)
-- Name: calls_customize_columns_orders calls_customize_columns_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.calls_customize_columns_orders
    ADD CONSTRAINT calls_customize_columns_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6412 (class 2606 OID 96360)
-- Name: calls_dashboard_customize_column_orders calls_dashboard_customize_column_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.calls_dashboard_customize_column_orders
    ADD CONSTRAINT calls_dashboard_customize_column_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6415 (class 2606 OID 96362)
-- Name: campaign_ads campaign_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_ads
    ADD CONSTRAINT campaign_ads_pkey PRIMARY KEY (id);


--
-- TOC entry 6420 (class 2606 OID 96364)
-- Name: campaign_bid_modifier_groups campaign_bid_modifier_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_bid_modifier_groups
    ADD CONSTRAINT campaign_bid_modifier_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 6424 (class 2606 OID 96366)
-- Name: campaign_bid_modifiers campaign_bid_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_bid_modifiers
    ADD CONSTRAINT campaign_bid_modifiers_pkey PRIMARY KEY (id);


--
-- TOC entry 6430 (class 2606 OID 96368)
-- Name: campaign_budgets campaign_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_budgets
    ADD CONSTRAINT campaign_budgets_pkey PRIMARY KEY (id);


--
-- TOC entry 6435 (class 2606 OID 96370)
-- Name: campaign_call_posts campaign_call_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_call_posts
    ADD CONSTRAINT campaign_call_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 6441 (class 2606 OID 96372)
-- Name: campaign_dashboard_colunm_orders campaign_dashboard_colunm_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_dashboard_colunm_orders
    ADD CONSTRAINT campaign_dashboard_colunm_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6444 (class 2606 OID 96374)
-- Name: campaign_filter_groups campaign_filter_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filter_groups
    ADD CONSTRAINT campaign_filter_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 6448 (class 2606 OID 96376)
-- Name: campaign_filter_packages campaign_filter_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filter_packages
    ADD CONSTRAINT campaign_filter_packages_pkey PRIMARY KEY (id);


--
-- TOC entry 6453 (class 2606 OID 96378)
-- Name: campaign_filters campaign_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filters
    ADD CONSTRAINT campaign_filters_pkey PRIMARY KEY (id);


--
-- TOC entry 6459 (class 2606 OID 96380)
-- Name: campaign_lead_integrations campaign_lead_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_lead_integrations
    ADD CONSTRAINT campaign_lead_integrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6464 (class 2606 OID 96382)
-- Name: campaign_lead_posts campaign_lead_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_lead_posts
    ADD CONSTRAINT campaign_lead_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 6469 (class 2606 OID 96384)
-- Name: campaign_monthly_spends campaign_monthly_spends_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_monthly_spends
    ADD CONSTRAINT campaign_monthly_spends_pkey PRIMARY KEY (id);


--
-- TOC entry 6474 (class 2606 OID 96386)
-- Name: campaign_notes campaign_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_notes
    ADD CONSTRAINT campaign_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 6479 (class 2606 OID 96388)
-- Name: campaign_pixel_columns campaign_pixel_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_pixel_columns
    ADD CONSTRAINT campaign_pixel_columns_pkey PRIMARY KEY (id);


--
-- TOC entry 6482 (class 2606 OID 96390)
-- Name: campaign_quote_funnels campaign_quote_funnels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_quote_funnels
    ADD CONSTRAINT campaign_quote_funnels_pkey PRIMARY KEY (id);


--
-- TOC entry 6487 (class 2606 OID 96392)
-- Name: campaign_schedules campaign_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_schedules
    ADD CONSTRAINT campaign_schedules_pkey PRIMARY KEY (id);


--
-- TOC entry 6492 (class 2606 OID 96394)
-- Name: campaign_source_settings campaign_source_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_source_settings
    ADD CONSTRAINT campaign_source_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6497 (class 2606 OID 96396)
-- Name: campaign_spends campaign_spends_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_spends
    ADD CONSTRAINT campaign_spends_pkey PRIMARY KEY (id);


--
-- TOC entry 6512 (class 2606 OID 96398)
-- Name: campaigns_customize_columns_orders campaigns_customize_columns_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns_customize_columns_orders
    ADD CONSTRAINT campaigns_customize_columns_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6503 (class 2606 OID 96400)
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- TOC entry 6515 (class 2606 OID 96402)
-- Name: ccpa_opted_out_users ccpa_opted_out_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ccpa_opted_out_users
    ADD CONSTRAINT ccpa_opted_out_users_pkey PRIMARY KEY (id);


--
-- TOC entry 6520 (class 2606 OID 96404)
-- Name: click_ad_group_settings click_ad_group_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ad_group_settings
    ADD CONSTRAINT click_ad_group_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6524 (class 2606 OID 96406)
-- Name: click_campaign_settings click_campaign_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_campaign_settings
    ADD CONSTRAINT click_campaign_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6528 (class 2606 OID 96408)
-- Name: click_conversion_errors click_conversion_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_errors
    ADD CONSTRAINT click_conversion_errors_pkey PRIMARY KEY (id);


--
-- TOC entry 6534 (class 2606 OID 96410)
-- Name: click_conversion_log_details click_conversion_log_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_log_details
    ADD CONSTRAINT click_conversion_log_details_pkey PRIMARY KEY (id);


--
-- TOC entry 6538 (class 2606 OID 96412)
-- Name: click_conversion_logs click_conversion_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_logs
    ADD CONSTRAINT click_conversion_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6545 (class 2606 OID 96414)
-- Name: click_conversion_pixels click_conversion_pixels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversion_pixels
    ADD CONSTRAINT click_conversion_pixels_pkey PRIMARY KEY (id);


--
-- TOC entry 6550 (class 2606 OID 96416)
-- Name: click_conversions click_conversions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_conversions
    ADD CONSTRAINT click_conversions_pkey PRIMARY KEY (id);


--
-- TOC entry 6566 (class 2606 OID 96418)
-- Name: click_integration_logs click_integration_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_integration_logs
    ADD CONSTRAINT click_integration_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6569 (class 2606 OID 96420)
-- Name: click_integration_types click_integration_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_integration_types
    ADD CONSTRAINT click_integration_types_pkey PRIMARY KEY (id);


--
-- TOC entry 6571 (class 2606 OID 96422)
-- Name: click_integrations click_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_integrations
    ADD CONSTRAINT click_integrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6574 (class 2606 OID 96424)
-- Name: click_listings click_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_listings
    ADD CONSTRAINT click_listings_pkey PRIMARY KEY (id);


--
-- TOC entry 6586 (class 2606 OID 96426)
-- Name: click_opportunities click_opportunities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_opportunities
    ADD CONSTRAINT click_opportunities_pkey PRIMARY KEY (id);


--
-- TOC entry 6599 (class 2606 OID 96428)
-- Name: click_panels click_panels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_panels
    ADD CONSTRAINT click_panels_pkey PRIMARY KEY (id);


--
-- TOC entry 6604 (class 2606 OID 96430)
-- Name: click_ping_debug_logs click_ping_debug_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_debug_logs
    ADD CONSTRAINT click_ping_debug_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6607 (class 2606 OID 96432)
-- Name: click_ping_details click_ping_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_details
    ADD CONSTRAINT click_ping_details_pkey PRIMARY KEY (id);


--
-- TOC entry 6614 (class 2606 OID 96434)
-- Name: click_ping_matches click_ping_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_matches
    ADD CONSTRAINT click_ping_matches_pkey PRIMARY KEY (id);


--
-- TOC entry 6621 (class 2606 OID 96436)
-- Name: click_ping_vals click_ping_vals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ping_vals
    ADD CONSTRAINT click_ping_vals_pkey PRIMARY KEY (id);


--
-- TOC entry 6624 (class 2606 OID 96438)
-- Name: click_pings click_pings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_pings
    ADD CONSTRAINT click_pings_pkey PRIMARY KEY (id);


--
-- TOC entry 6634 (class 2606 OID 96440)
-- Name: click_posts click_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_posts
    ADD CONSTRAINT click_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 6639 (class 2606 OID 96442)
-- Name: click_receipts click_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_receipts
    ADD CONSTRAINT click_receipts_pkey PRIMARY KEY (id);


--
-- TOC entry 6647 (class 2606 OID 96444)
-- Name: click_results click_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_results
    ADD CONSTRAINT click_results_pkey PRIMARY KEY (id);


--
-- TOC entry 6651 (class 2606 OID 96446)
-- Name: clicks_dashboard_customize_column_orders clicks_dashboard_customize_column_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clicks_dashboard_customize_column_orders
    ADD CONSTRAINT clicks_dashboard_customize_column_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6654 (class 2606 OID 96448)
-- Name: close_com_items close_com_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.close_com_items
    ADD CONSTRAINT close_com_items_pkey PRIMARY KEY (id);


--
-- TOC entry 6660 (class 2606 OID 96450)
-- Name: conversion_log_transactions conversion_log_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversion_log_transactions
    ADD CONSTRAINT conversion_log_transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 6666 (class 2606 OID 96452)
-- Name: conversions_logs_pixel_cols conversions_logs_pixel_cols_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversions_logs_pixel_cols
    ADD CONSTRAINT conversions_logs_pixel_cols_pkey PRIMARY KEY (id);


--
-- TOC entry 6669 (class 2606 OID 96454)
-- Name: custom_intermediate_integration_configs custom_intermediate_integration_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_intermediate_integration_configs
    ADD CONSTRAINT custom_intermediate_integration_configs_pkey PRIMARY KEY (id);


--
-- TOC entry 6673 (class 2606 OID 96456)
-- Name: customize_orders customize_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customize_orders
    ADD CONSTRAINT customize_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6676 (class 2606 OID 96458)
-- Name: days days_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days
    ADD CONSTRAINT days_pkey PRIMARY KEY (id);


--
-- TOC entry 6678 (class 2606 OID 96460)
-- Name: dms_logs dms_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dms_logs
    ADD CONSTRAINT dms_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6683 (class 2606 OID 96462)
-- Name: email_events email_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_events
    ADD CONSTRAINT email_events_pkey PRIMARY KEY (id);


--
-- TOC entry 6685 (class 2606 OID 96464)
-- Name: email_export_logs email_export_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_export_logs
    ADD CONSTRAINT email_export_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6690 (class 2606 OID 96466)
-- Name: email_template_logs email_template_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_template_logs
    ADD CONSTRAINT email_template_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6692 (class 2606 OID 96468)
-- Name: farmers_skus farmers_skus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_skus
    ADD CONSTRAINT farmers_skus_pkey PRIMARY KEY (id);


--
-- TOC entry 6694 (class 2606 OID 96470)
-- Name: features features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (id);


--
-- TOC entry 6697 (class 2606 OID 96472)
-- Name: filter_package_filters filter_package_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filter_package_filters
    ADD CONSTRAINT filter_package_filters_pkey PRIMARY KEY (id);


--
-- TOC entry 6702 (class 2606 OID 96474)
-- Name: filter_packages filter_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filter_packages
    ADD CONSTRAINT filter_packages_pkey PRIMARY KEY (id);


--
-- TOC entry 6705 (class 2606 OID 96476)
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- TOC entry 6708 (class 2606 OID 96478)
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- TOC entry 6711 (class 2606 OID 96480)
-- Name: history_versions history_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history_versions
    ADD CONSTRAINT history_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 6724 (class 2606 OID 96482)
-- Name: insurance_carriers insurance_carriers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insurance_carriers
    ADD CONSTRAINT insurance_carriers_pkey PRIMARY KEY (id);


--
-- TOC entry 6726 (class 2606 OID 96484)
-- Name: intermediate_lead_integrations intermediate_lead_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intermediate_lead_integrations
    ADD CONSTRAINT intermediate_lead_integrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6728 (class 2606 OID 96486)
-- Name: internal_api_tokens internal_api_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_api_tokens
    ADD CONSTRAINT internal_api_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 6731 (class 2606 OID 96488)
-- Name: invoice_raw_stats invoice_raw_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_raw_stats
    ADD CONSTRAINT invoice_raw_stats_pkey PRIMARY KEY (id);


--
-- TOC entry 6737 (class 2606 OID 96490)
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- TOC entry 6739 (class 2606 OID 96492)
-- Name: jira_users jira_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jira_users
    ADD CONSTRAINT jira_users_pkey PRIMARY KEY (id);


--
-- TOC entry 6742 (class 2606 OID 96494)
-- Name: jwt_denylist jwt_denylist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jwt_denylist
    ADD CONSTRAINT jwt_denylist_pkey PRIMARY KEY (id);


--
-- TOC entry 6747 (class 2606 OID 96496)
-- Name: lead_applicants lead_applicants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_applicants
    ADD CONSTRAINT lead_applicants_pkey PRIMARY KEY (id);


--
-- TOC entry 6751 (class 2606 OID 96498)
-- Name: lead_business_entities lead_business_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_business_entities
    ADD CONSTRAINT lead_business_entities_pkey PRIMARY KEY (id);


--
-- TOC entry 6756 (class 2606 OID 96500)
-- Name: lead_campaign_settings lead_campaign_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_campaign_settings
    ADD CONSTRAINT lead_campaign_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6763 (class 2606 OID 96502)
-- Name: lead_details lead_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_details
    ADD CONSTRAINT lead_details_pkey PRIMARY KEY (id);


--
-- TOC entry 6767 (class 2606 OID 96504)
-- Name: lead_homes lead_homes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_homes
    ADD CONSTRAINT lead_homes_pkey PRIMARY KEY (id);


--
-- TOC entry 6770 (class 2606 OID 96506)
-- Name: lead_integration_failure_reasons lead_integration_failure_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_failure_reasons
    ADD CONSTRAINT lead_integration_failure_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 6774 (class 2606 OID 96508)
-- Name: lead_integration_macro_mappings lead_integration_macro_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_macro_mappings
    ADD CONSTRAINT lead_integration_macro_mappings_pkey PRIMARY KEY (id);


--
-- TOC entry 6780 (class 2606 OID 96510)
-- Name: lead_integration_macros lead_integration_macros_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_macros
    ADD CONSTRAINT lead_integration_macros_pkey PRIMARY KEY (id);


--
-- TOC entry 6784 (class 2606 OID 96512)
-- Name: lead_integration_req_headers lead_integration_req_headers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_headers
    ADD CONSTRAINT lead_integration_req_headers_pkey PRIMARY KEY (id);


--
-- TOC entry 6789 (class 2606 OID 96514)
-- Name: lead_integration_req_logs lead_integration_req_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_logs
    ADD CONSTRAINT lead_integration_req_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6793 (class 2606 OID 96516)
-- Name: lead_integration_req_payloads lead_integration_req_payloads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_payloads
    ADD CONSTRAINT lead_integration_req_payloads_pkey PRIMARY KEY (id);


--
-- TOC entry 6798 (class 2606 OID 96518)
-- Name: lead_integrations lead_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integrations
    ADD CONSTRAINT lead_integrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6806 (class 2606 OID 96520)
-- Name: lead_listings lead_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_listings
    ADD CONSTRAINT lead_listings_pkey PRIMARY KEY (id);


--
-- TOC entry 6814 (class 2606 OID 96522)
-- Name: lead_opportunities lead_opportunities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_opportunities
    ADD CONSTRAINT lead_opportunities_pkey PRIMARY KEY (id);


--
-- TOC entry 6818 (class 2606 OID 96524)
-- Name: lead_ping_debug_logs lead_ping_debug_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_ping_debug_logs
    ADD CONSTRAINT lead_ping_debug_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6821 (class 2606 OID 96526)
-- Name: lead_ping_details lead_ping_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_ping_details
    ADD CONSTRAINT lead_ping_details_pkey PRIMARY KEY (id);


--
-- TOC entry 6828 (class 2606 OID 96528)
-- Name: lead_ping_matches lead_ping_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_ping_matches
    ADD CONSTRAINT lead_ping_matches_pkey PRIMARY KEY (id);


--
-- TOC entry 6836 (class 2606 OID 96530)
-- Name: lead_pings lead_pings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_pings
    ADD CONSTRAINT lead_pings_pkey PRIMARY KEY (id);


--
-- TOC entry 6840 (class 2606 OID 96532)
-- Name: lead_post_details lead_post_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_post_details
    ADD CONSTRAINT lead_post_details_pkey PRIMARY KEY (id);


--
-- TOC entry 6845 (class 2606 OID 96534)
-- Name: lead_post_legs lead_post_legs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_post_legs
    ADD CONSTRAINT lead_post_legs_pkey PRIMARY KEY (id);


--
-- TOC entry 6851 (class 2606 OID 96536)
-- Name: lead_posts lead_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_posts
    ADD CONSTRAINT lead_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 6855 (class 2606 OID 96538)
-- Name: lead_prices lead_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_prices
    ADD CONSTRAINT lead_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 6858 (class 2606 OID 96540)
-- Name: lead_refund_reasons lead_refund_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_refund_reasons
    ADD CONSTRAINT lead_refund_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 6862 (class 2606 OID 96542)
-- Name: lead_refunds lead_refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_refunds
    ADD CONSTRAINT lead_refunds_pkey PRIMARY KEY (id);


--
-- TOC entry 6864 (class 2606 OID 96544)
-- Name: lead_types lead_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_types
    ADD CONSTRAINT lead_types_pkey PRIMARY KEY (id);


--
-- TOC entry 6869 (class 2606 OID 96546)
-- Name: lead_vehicles lead_vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_vehicles
    ADD CONSTRAINT lead_vehicles_pkey PRIMARY KEY (id);


--
-- TOC entry 6876 (class 2606 OID 96548)
-- Name: lead_violations lead_violations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_violations
    ADD CONSTRAINT lead_violations_pkey PRIMARY KEY (id);


--
-- TOC entry 6886 (class 2606 OID 96550)
-- Name: leads_customize_columns_orders leads_customize_columns_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads_customize_columns_orders
    ADD CONSTRAINT leads_customize_columns_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6889 (class 2606 OID 96552)
-- Name: leads_dashboard_customize_column_orders leads_dashboard_customize_column_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads_dashboard_customize_column_orders
    ADD CONSTRAINT leads_dashboard_customize_column_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6883 (class 2606 OID 96554)
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- TOC entry 6894 (class 2606 OID 96556)
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- TOC entry 6899 (class 2606 OID 96558)
-- Name: mv_refresh_statuses mv_refresh_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mv_refresh_statuses
    ADD CONSTRAINT mv_refresh_statuses_pkey PRIMARY KEY (id);


--
-- TOC entry 6907 (class 2606 OID 96560)
-- Name: non_rtb_ping_stats non_rtb_ping_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.non_rtb_ping_stats
    ADD CONSTRAINT non_rtb_ping_stats_pkey PRIMARY KEY (id);


--
-- TOC entry 6912 (class 2606 OID 96562)
-- Name: notification_events notification_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_events
    ADD CONSTRAINT notification_events_pkey PRIMARY KEY (id);


--
-- TOC entry 6915 (class 2606 OID 96564)
-- Name: notification_job_sources notification_job_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_job_sources
    ADD CONSTRAINT notification_job_sources_pkey PRIMARY KEY (id);


--
-- TOC entry 6919 (class 2606 OID 96566)
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- TOC entry 6922 (class 2606 OID 96568)
-- Name: old_passwords old_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.old_passwords
    ADD CONSTRAINT old_passwords_pkey PRIMARY KEY (id);


--
-- TOC entry 6925 (class 2606 OID 96570)
-- Name: page_groups page_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_groups
    ADD CONSTRAINT page_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 6929 (class 2606 OID 96572)
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- TOC entry 6931 (class 2606 OID 96574)
-- Name: payment_terms payment_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_terms
    ADD CONSTRAINT payment_terms_pkey PRIMARY KEY (id);


--
-- TOC entry 6935 (class 2606 OID 96576)
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 6937 (class 2606 OID 96578)
-- Name: platform_settings platform_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.platform_settings
    ADD CONSTRAINT platform_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6941 (class 2606 OID 96580)
-- Name: popup_lead_type_messages popup_lead_type_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.popup_lead_type_messages
    ADD CONSTRAINT popup_lead_type_messages_pkey PRIMARY KEY (id);


--
-- TOC entry 6946 (class 2606 OID 96582)
-- Name: postback_url_req_logs postback_url_req_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postback_url_req_logs
    ADD CONSTRAINT postback_url_req_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6949 (class 2606 OID 96584)
-- Name: pp_ping_report_accounts pp_ping_report_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pp_ping_report_accounts
    ADD CONSTRAINT pp_ping_report_accounts_pkey PRIMARY KEY (id);


--
-- TOC entry 6957 (class 2606 OID 96586)
-- Name: prefill_queries prefill_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prefill_queries
    ADD CONSTRAINT prefill_queries_pkey PRIMARY KEY (id);


--
-- TOC entry 6959 (class 2606 OID 96588)
-- Name: product_types product_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_pkey PRIMARY KEY (id);


--
-- TOC entry 6962 (class 2606 OID 96590)
-- Name: prospects_customize_columns_orders prospects_customize_columns_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prospects_customize_columns_orders
    ADD CONSTRAINT prospects_customize_columns_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 6966 (class 2606 OID 96592)
-- Name: qf_call_integrations qf_call_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_call_integrations
    ADD CONSTRAINT qf_call_integrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6970 (class 2606 OID 96594)
-- Name: qf_call_settings qf_call_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_call_settings
    ADD CONSTRAINT qf_call_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6974 (class 2606 OID 96596)
-- Name: qf_lead_integrations qf_lead_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_lead_integrations
    ADD CONSTRAINT qf_lead_integrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6978 (class 2606 OID 96598)
-- Name: qf_lead_settings qf_lead_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_lead_settings
    ADD CONSTRAINT qf_lead_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6981 (class 2606 OID 96600)
-- Name: qf_quote_call_qas qf_quote_call_qas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_qas
    ADD CONSTRAINT qf_quote_call_qas_pkey PRIMARY KEY (id);


--
-- TOC entry 6984 (class 2606 OID 96602)
-- Name: qf_quote_call_summaries qf_quote_call_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_summaries
    ADD CONSTRAINT qf_quote_call_summaries_pkey PRIMARY KEY (id);


--
-- TOC entry 6987 (class 2606 OID 96604)
-- Name: qf_quote_call_transcriptions qf_quote_call_transcriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_transcriptions
    ADD CONSTRAINT qf_quote_call_transcriptions_pkey PRIMARY KEY (id);


--
-- TOC entry 6996 (class 2606 OID 96606)
-- Name: qf_quote_calls qf_quote_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_calls
    ADD CONSTRAINT qf_quote_calls_pkey PRIMARY KEY (id);


--
-- TOC entry 7001 (class 2606 OID 96608)
-- Name: question_groups question_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.question_groups
    ADD CONSTRAINT question_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 7007 (class 2606 OID 96610)
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- TOC entry 7010 (class 2606 OID 96612)
-- Name: quote_call_qas quote_call_qas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_qas
    ADD CONSTRAINT quote_call_qas_pkey PRIMARY KEY (id);


--
-- TOC entry 7013 (class 2606 OID 96614)
-- Name: quote_call_summaries quote_call_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_summaries
    ADD CONSTRAINT quote_call_summaries_pkey PRIMARY KEY (id);


--
-- TOC entry 7017 (class 2606 OID 96616)
-- Name: quote_call_transcriptions quote_call_transcriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_transcriptions
    ADD CONSTRAINT quote_call_transcriptions_pkey PRIMARY KEY (id);


--
-- TOC entry 7026 (class 2606 OID 96618)
-- Name: quote_calls quote_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_calls
    ADD CONSTRAINT quote_calls_pkey PRIMARY KEY (id);


--
-- TOC entry 7030 (class 2606 OID 96620)
-- Name: quote_form_visits quote_form_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_form_visits
    ADD CONSTRAINT quote_form_visits_pkey PRIMARY KEY (id);


--
-- TOC entry 7034 (class 2606 OID 96622)
-- Name: quote_funnels quote_funnels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_funnels
    ADD CONSTRAINT quote_funnels_pkey PRIMARY KEY (id);


--
-- TOC entry 7037 (class 2606 OID 96624)
-- Name: quote_funnels_prices quote_funnels_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_funnels_prices
    ADD CONSTRAINT quote_funnels_prices_pkey PRIMARY KEY (id);


--
-- TOC entry 7043 (class 2606 OID 96626)
-- Name: rds_logs rds_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rds_logs
    ADD CONSTRAINT rds_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 7045 (class 2606 OID 96628)
-- Name: receipt_transaction_types receipt_transaction_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipt_transaction_types
    ADD CONSTRAINT receipt_transaction_types_pkey PRIMARY KEY (id);


--
-- TOC entry 7047 (class 2606 OID 96630)
-- Name: receipt_types receipt_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipt_types
    ADD CONSTRAINT receipt_types_pkey PRIMARY KEY (id);


--
-- TOC entry 7059 (class 2606 OID 96632)
-- Name: receipts receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipts
    ADD CONSTRAINT receipts_pkey PRIMARY KEY (id);


--
-- TOC entry 7063 (class 2606 OID 96634)
-- Name: recently_visited_client_users recently_visited_client_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recently_visited_client_users
    ADD CONSTRAINT recently_visited_client_users_pkey PRIMARY KEY (id);


--
-- TOC entry 7069 (class 2606 OID 96636)
-- Name: registration_pending_users registration_pending_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_pending_users
    ADD CONSTRAINT registration_pending_users_pkey PRIMARY KEY (id);


--
-- TOC entry 7071 (class 2606 OID 96638)
-- Name: response_parser_functions response_parser_functions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.response_parser_functions
    ADD CONSTRAINT response_parser_functions_pkey PRIMARY KEY (id);


--
-- TOC entry 7076 (class 2606 OID 96640)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 7079 (class 2606 OID 96642)
-- Name: rtb_bids rtb_bids_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rtb_bids
    ADD CONSTRAINT rtb_bids_pkey PRIMARY KEY (id);


--
-- TOC entry 7086 (class 2606 OID 96644)
-- Name: rule_validator_checks rule_validator_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rule_validator_checks
    ADD CONSTRAINT rule_validator_checks_pkey PRIMARY KEY (id);


--
-- TOC entry 7089 (class 2606 OID 96646)
-- Name: sample_leads sample_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sample_leads
    ADD CONSTRAINT sample_leads_pkey PRIMARY KEY (id);


--
-- TOC entry 7092 (class 2606 OID 96648)
-- Name: scheduled_report_emails scheduled_report_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_emails
    ADD CONSTRAINT scheduled_report_emails_pkey PRIMARY KEY (id);


--
-- TOC entry 7097 (class 2606 OID 96650)
-- Name: scheduled_report_logs scheduled_report_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_logs
    ADD CONSTRAINT scheduled_report_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 7100 (class 2606 OID 96652)
-- Name: scheduled_report_sftps scheduled_report_sftps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_sftps
    ADD CONSTRAINT scheduled_report_sftps_pkey PRIMARY KEY (id);


--
-- TOC entry 7104 (class 2606 OID 96654)
-- Name: scheduled_report_uploads scheduled_report_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_uploads
    ADD CONSTRAINT scheduled_report_uploads_pkey PRIMARY KEY (id);


--
-- TOC entry 7111 (class 2606 OID 96656)
-- Name: scheduled_reports scheduled_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_reports
    ADD CONSTRAINT scheduled_reports_pkey PRIMARY KEY (id);


--
-- TOC entry 7113 (class 2606 OID 96658)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 7116 (class 2606 OID 96660)
-- Name: semaphore_deployments semaphore_deployments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semaphore_deployments
    ADD CONSTRAINT semaphore_deployments_pkey PRIMARY KEY (id);


--
-- TOC entry 7121 (class 2606 OID 96662)
-- Name: sf_filters sf_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_filters
    ADD CONSTRAINT sf_filters_pkey PRIMARY KEY (id);


--
-- TOC entry 7123 (class 2606 OID 96664)
-- Name: sf_lead_integration_macro_categories sf_lead_integration_macro_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macro_categories
    ADD CONSTRAINT sf_lead_integration_macro_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 7127 (class 2606 OID 96666)
-- Name: sf_lead_integration_macro_lead_types sf_lead_integration_macro_lead_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macro_lead_types
    ADD CONSTRAINT sf_lead_integration_macro_lead_types_pkey PRIMARY KEY (id);


--
-- TOC entry 7130 (class 2606 OID 96668)
-- Name: sf_lead_integration_macros sf_lead_integration_macros_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macros
    ADD CONSTRAINT sf_lead_integration_macros_pkey PRIMARY KEY (id);


--
-- TOC entry 7133 (class 2606 OID 96670)
-- Name: sf_smart_views sf_smart_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_smart_views
    ADD CONSTRAINT sf_smart_views_pkey PRIMARY KEY (id);


--
-- TOC entry 7137 (class 2606 OID 96672)
-- Name: sidekiq_job_error_logs sidekiq_job_error_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sidekiq_job_error_logs
    ADD CONSTRAINT sidekiq_job_error_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 7139 (class 2606 OID 96674)
-- Name: slack_support_channel_requests slack_support_channel_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slack_support_channel_requests
    ADD CONSTRAINT slack_support_channel_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 7142 (class 2606 OID 96676)
-- Name: slow_query_logs slow_query_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slow_query_logs
    ADD CONSTRAINT slow_query_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 7145 (class 2606 OID 96678)
-- Name: source_pixel_columns source_pixel_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_pixel_columns
    ADD CONSTRAINT source_pixel_columns_pkey PRIMARY KEY (id);


--
-- TOC entry 7150 (class 2606 OID 96680)
-- Name: source_setting_notes source_setting_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_setting_notes
    ADD CONSTRAINT source_setting_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 7154 (class 2606 OID 96682)
-- Name: source_types source_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_types
    ADD CONSTRAINT source_types_pkey PRIMARY KEY (id);


--
-- TOC entry 7157 (class 2606 OID 96684)
-- Name: state_names state_names_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.state_names
    ADD CONSTRAINT state_names_pkey PRIMARY KEY (id);


--
-- TOC entry 7161 (class 2606 OID 96686)
-- Name: syndi_click_rules syndi_click_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.syndi_click_rules
    ADD CONSTRAINT syndi_click_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 7166 (class 2606 OID 96688)
-- Name: syndi_click_settings syndi_click_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.syndi_click_settings
    ADD CONSTRAINT syndi_click_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 7171 (class 2606 OID 96690)
-- Name: template_assignments template_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_assignments
    ADD CONSTRAINT template_assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 7173 (class 2606 OID 96692)
-- Name: terms_of_services terms_of_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terms_of_services
    ADD CONSTRAINT terms_of_services_pkey PRIMARY KEY (id);


--
-- TOC entry 7175 (class 2606 OID 96694)
-- Name: trusted_form_certificates trusted_form_certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trusted_form_certificates
    ADD CONSTRAINT trusted_form_certificates_pkey PRIMARY KEY (id);


--
-- TOC entry 7181 (class 2606 OID 96696)
-- Name: twilio_phone_numbers twilio_phone_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_phone_numbers
    ADD CONSTRAINT twilio_phone_numbers_pkey PRIMARY KEY (id);


--
-- TOC entry 7184 (class 2606 OID 96698)
-- Name: user_activity_customize_columns_orders user_activity_customize_columns_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_activity_customize_columns_orders
    ADD CONSTRAINT user_activity_customize_columns_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 7187 (class 2606 OID 96700)
-- Name: user_col_pref_admin_dashboards user_col_pref_admin_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_admin_dashboards
    ADD CONSTRAINT user_col_pref_admin_dashboards_pkey PRIMARY KEY (id);


--
-- TOC entry 7190 (class 2606 OID 96702)
-- Name: user_col_pref_analytics user_col_pref_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_analytics
    ADD CONSTRAINT user_col_pref_analytics_pkey PRIMARY KEY (id);


--
-- TOC entry 7193 (class 2606 OID 96704)
-- Name: user_col_pref_calls_dashboard_campaigns user_col_pref_calls_dashboard_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_calls_dashboard_campaigns
    ADD CONSTRAINT user_col_pref_calls_dashboard_campaigns_pkey PRIMARY KEY (id);


--
-- TOC entry 7196 (class 2606 OID 96706)
-- Name: user_col_pref_calls_dashboard_states user_col_pref_calls_dashboard_states_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_calls_dashboard_states
    ADD CONSTRAINT user_col_pref_calls_dashboard_states_pkey PRIMARY KEY (id);


--
-- TOC entry 7199 (class 2606 OID 96708)
-- Name: user_col_pref_clicks_dashboards user_col_pref_clicks_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_clicks_dashboards
    ADD CONSTRAINT user_col_pref_clicks_dashboards_pkey PRIMARY KEY (id);


--
-- TOC entry 7202 (class 2606 OID 96710)
-- Name: user_col_pref_conversion_logs user_col_pref_conversion_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_conversion_logs
    ADD CONSTRAINT user_col_pref_conversion_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 7205 (class 2606 OID 96712)
-- Name: user_col_pref_leads_dashboards user_col_pref_leads_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_leads_dashboards
    ADD CONSTRAINT user_col_pref_leads_dashboards_pkey PRIMARY KEY (id);


--
-- TOC entry 7208 (class 2606 OID 96714)
-- Name: user_col_pref_syndi_clicks_dashboards user_col_pref_syndi_clicks_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_syndi_clicks_dashboards
    ADD CONSTRAINT user_col_pref_syndi_clicks_dashboards_pkey PRIMARY KEY (id);


--
-- TOC entry 7211 (class 2606 OID 96716)
-- Name: user_column_preference_ad_groups user_column_preference_ad_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_ad_groups
    ADD CONSTRAINT user_column_preference_ad_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 7214 (class 2606 OID 96718)
-- Name: user_column_preference_call_profiles user_column_preference_call_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_call_profiles
    ADD CONSTRAINT user_column_preference_call_profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 7217 (class 2606 OID 96720)
-- Name: user_column_preference_call_source_settings user_column_preference_call_source_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_call_source_settings
    ADD CONSTRAINT user_column_preference_call_source_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 7220 (class 2606 OID 96722)
-- Name: user_column_preference_calls user_column_preference_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_calls
    ADD CONSTRAINT user_column_preference_calls_pkey PRIMARY KEY (id);


--
-- TOC entry 7223 (class 2606 OID 96724)
-- Name: user_column_preference_campaigns user_column_preference_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_campaigns
    ADD CONSTRAINT user_column_preference_campaigns_pkey PRIMARY KEY (id);


--
-- TOC entry 7226 (class 2606 OID 96726)
-- Name: user_column_preference_lead_profiles user_column_preference_lead_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_lead_profiles
    ADD CONSTRAINT user_column_preference_lead_profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 7229 (class 2606 OID 96728)
-- Name: user_column_preference_lead_source_settings user_column_preference_lead_source_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_lead_source_settings
    ADD CONSTRAINT user_column_preference_lead_source_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 7232 (class 2606 OID 96730)
-- Name: user_column_preference_leads user_column_preference_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_leads
    ADD CONSTRAINT user_column_preference_leads_pkey PRIMARY KEY (id);


--
-- TOC entry 7235 (class 2606 OID 96732)
-- Name: user_column_preference_prospects user_column_preference_prospects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_prospects
    ADD CONSTRAINT user_column_preference_prospects_pkey PRIMARY KEY (id);


--
-- TOC entry 7238 (class 2606 OID 96734)
-- Name: user_column_preference_source_settings user_column_preference_source_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_source_settings
    ADD CONSTRAINT user_column_preference_source_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 7242 (class 2606 OID 96736)
-- Name: user_notifications user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 7247 (class 2606 OID 96738)
-- Name: user_smart_views user_smart_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_smart_views
    ADD CONSTRAINT user_smart_views_pkey PRIMARY KEY (id);


--
-- TOC entry 7251 (class 2606 OID 96740)
-- Name: user_terms_of_services user_terms_of_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_terms_of_services
    ADD CONSTRAINT user_terms_of_services_pkey PRIMARY KEY (id);


--
-- TOC entry 7256 (class 2606 OID 96742)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 7265 (class 2606 OID 96744)
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- TOC entry 7267 (class 2606 OID 96746)
-- Name: violation_types violation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.violation_types
    ADD CONSTRAINT violation_types_pkey PRIMARY KEY (id);


--
-- TOC entry 7270 (class 2606 OID 96748)
-- Name: white_listing_brands white_listing_brands_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.white_listing_brands
    ADD CONSTRAINT white_listing_brands_pkey PRIMARY KEY (id);


--
-- TOC entry 7274 (class 2606 OID 96750)
-- Name: whitelabeled_brands_user_login_mappings whitelabeled_brands_user_login_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelabeled_brands_user_login_mappings
    ADD CONSTRAINT whitelabeled_brands_user_login_mappings_pkey PRIMARY KEY (id);


--
-- TOC entry 7279 (class 2606 OID 96752)
-- Name: whitelisting_brand_admin_assignments whitelisting_brand_admin_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelisting_brand_admin_assignments
    ADD CONSTRAINT whitelisting_brand_admin_assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 7283 (class 2606 OID 96754)
-- Name: zip_tier_locations zip_tier_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zip_tier_locations
    ADD CONSTRAINT zip_tier_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 7287 (class 2606 OID 96756)
-- Name: zip_tiers zip_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zip_tiers
    ADD CONSTRAINT zip_tiers_pkey PRIMARY KEY (id);


--
-- TOC entry 7290 (class 2606 OID 96758)
-- Name: zipcodes zipcodes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zipcodes
    ADD CONSTRAINT zipcodes_pkey PRIMARY KEY (id);


--
-- TOC entry 6180 (class 1259 OID 96759)
-- Name: agl_zip_ag; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agl_zip_ag ON public.ad_group_locations USING btree (zip, ad_group_id);


--
-- TOC entry 6643 (class 1259 OID 96760)
-- Name: click_results_aggr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX click_results_aggr ON public.click_results USING btree (click_ping_id, account_id, campaign_id, ad_group_id);


--
-- TOC entry 6644 (class 1259 OID 96761)
-- Name: click_results_click_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX click_results_click_id ON public.click_results USING btree (click_id);


--
-- TOC entry 6645 (class 1259 OID 96762)
-- Name: click_results_cmp_ts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX click_results_cmp_ts ON public.click_results USING btree (campaign_id, created_at);


--
-- TOC entry 6504 (class 1259 OID 96763)
-- Name: cmp_aggr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cmp_aggr ON public.campaigns USING btree (product_type_id, lead_type_id, active, discarded_at);


--
-- TOC entry 6153 (class 1259 OID 96764)
-- Name: index_account_balances_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_account_balances_on_user_id ON public.account_balances USING btree (user_id);


--
-- TOC entry 6156 (class 1259 OID 96765)
-- Name: index_accounts_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_accounts_on_discarded_at ON public.accounts USING btree (discarded_at);


--
-- TOC entry 6157 (class 1259 OID 96766)
-- Name: index_accounts_on_insurance_carrier_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_accounts_on_insurance_carrier_id ON public.accounts USING btree (insurance_carrier_id);


--
-- TOC entry 6158 (class 1259 OID 96767)
-- Name: index_accounts_on_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_accounts_on_uuid ON public.accounts USING btree (uuid);


--
-- TOC entry 6161 (class 1259 OID 96768)
-- Name: index_ad_contents_on_ad_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_contents_on_ad_id ON public.ad_contents USING btree (ad_id);


--
-- TOC entry 6162 (class 1259 OID 96769)
-- Name: index_ad_contents_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_contents_on_discarded_at ON public.ad_contents USING btree (discarded_at);


--
-- TOC entry 6165 (class 1259 OID 96770)
-- Name: index_ad_group_ads_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_ads_on_ad_group_id ON public.ad_group_ads USING btree (ad_group_id);


--
-- TOC entry 6166 (class 1259 OID 96771)
-- Name: index_ad_group_ads_on_ad_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_ads_on_ad_id ON public.ad_group_ads USING btree (ad_id);


--
-- TOC entry 6167 (class 1259 OID 96772)
-- Name: index_ad_group_ads_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_ads_on_discarded_at ON public.ad_group_ads USING btree (discarded_at);


--
-- TOC entry 6170 (class 1259 OID 96773)
-- Name: index_ad_group_filter_groups_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_filter_groups_on_ad_group_id ON public.ad_group_filter_groups USING btree (ad_group_id);


--
-- TOC entry 6171 (class 1259 OID 96774)
-- Name: index_ad_group_filter_groups_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_filter_groups_on_discarded_at ON public.ad_group_filter_groups USING btree (discarded_at);


--
-- TOC entry 6174 (class 1259 OID 96775)
-- Name: index_ad_group_filters_on_ad_group_filter_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_filters_on_ad_group_filter_group_id ON public.ad_group_filters USING btree (ad_group_filter_group_id);


--
-- TOC entry 6175 (class 1259 OID 96776)
-- Name: index_ad_group_filters_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_filters_on_ad_group_id ON public.ad_group_filters USING btree (ad_group_id);


--
-- TOC entry 6176 (class 1259 OID 96777)
-- Name: index_ad_group_filters_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_filters_on_discarded_at ON public.ad_group_filters USING btree (discarded_at);


--
-- TOC entry 6177 (class 1259 OID 96778)
-- Name: index_ad_group_filters_on_sf_filter_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_filters_on_sf_filter_id ON public.ad_group_filters USING btree (sf_filter_id);


--
-- TOC entry 6181 (class 1259 OID 96779)
-- Name: index_ad_group_locations_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_locations_on_ad_group_id ON public.ad_group_locations USING btree (ad_group_id);


--
-- TOC entry 6182 (class 1259 OID 96780)
-- Name: index_ad_group_locations_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_locations_on_discarded_at ON public.ad_group_locations USING btree (discarded_at);


--
-- TOC entry 6183 (class 1259 OID 96781)
-- Name: index_ad_group_locations_on_state; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_locations_on_state ON public.ad_group_locations USING btree (state);


--
-- TOC entry 6184 (class 1259 OID 96782)
-- Name: index_ad_group_locations_on_zip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_locations_on_zip ON public.ad_group_locations USING btree (zip);


--
-- TOC entry 6187 (class 1259 OID 96783)
-- Name: index_ad_group_notes_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_notes_on_ad_group_id ON public.ad_group_notes USING btree (ad_group_id);


--
-- TOC entry 6188 (class 1259 OID 96784)
-- Name: index_ad_group_notes_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_notes_on_admin_user_id ON public.ad_group_notes USING btree (admin_user_id);


--
-- TOC entry 6189 (class 1259 OID 96785)
-- Name: index_ad_group_notes_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_notes_on_discarded_at ON public.ad_group_notes USING btree (discarded_at);


--
-- TOC entry 6192 (class 1259 OID 96786)
-- Name: index_ad_group_pixel_columns_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_group_pixel_columns_on_click_conversion_pixel_id ON public.ad_group_pixel_columns USING btree (click_conversion_pixel_id);


--
-- TOC entry 6195 (class 1259 OID 96787)
-- Name: index_ad_groups_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_groups_on_account_id ON public.ad_groups USING btree (account_id);


--
-- TOC entry 6196 (class 1259 OID 96788)
-- Name: index_ad_groups_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_groups_on_campaign_id ON public.ad_groups USING btree (campaign_id);


--
-- TOC entry 6197 (class 1259 OID 96789)
-- Name: index_ad_groups_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ad_groups_on_discarded_at ON public.ad_groups USING btree (discarded_at);


--
-- TOC entry 6200 (class 1259 OID 96790)
-- Name: index_admin_assignments_on_admin_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_assignments_on_admin_role_id ON public.admin_assignments USING btree (admin_role_id);


--
-- TOC entry 6201 (class 1259 OID 96791)
-- Name: index_admin_assignments_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_assignments_on_admin_user_id ON public.admin_assignments USING btree (admin_user_id);


--
-- TOC entry 6202 (class 1259 OID 96792)
-- Name: index_admin_assignments_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_assignments_on_discarded_at ON public.admin_assignments USING btree (discarded_at);


--
-- TOC entry 6205 (class 1259 OID 96793)
-- Name: index_admin_clients_customize_columns_orders_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_clients_customize_columns_orders_on_admin_user_id ON public.admin_clients_customize_columns_orders USING btree (admin_user_id);


--
-- TOC entry 6208 (class 1259 OID 96794)
-- Name: index_admin_features_on_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_admin_features_on_name ON public.admin_features USING btree (name);


--
-- TOC entry 6241 (class 1259 OID 96795)
-- Name: index_admin_notification_preferences_on_notification_types; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_notification_preferences_on_notification_types ON public.admin_user_notifications_preferences USING btree (admin_notification_type_id);


--
-- TOC entry 6211 (class 1259 OID 96796)
-- Name: index_admin_notification_template_types_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_notification_template_types_on_discarded_at ON public.admin_notification_template_types USING btree (discarded_at);


--
-- TOC entry 6212 (class 1259 OID 96797)
-- Name: index_admin_notification_template_types_on_templates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_notification_template_types_on_templates ON public.admin_notification_template_types USING btree (admin_notification_template_id);


--
-- TOC entry 6216 (class 1259 OID 96798)
-- Name: index_admin_notification_templates_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_notification_templates_on_discarded_at ON public.admin_notification_templates USING btree (discarded_at);


--
-- TOC entry 6213 (class 1259 OID 96799)
-- Name: index_admin_notification_types_on_templates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_notification_types_on_templates ON public.admin_notification_template_types USING btree (admin_notification_type_id);


--
-- TOC entry 6221 (class 1259 OID 96800)
-- Name: index_admin_permissions_on_admin_feature_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_permissions_on_admin_feature_id ON public.admin_permissions USING btree (admin_feature_id);


--
-- TOC entry 6222 (class 1259 OID 96801)
-- Name: index_admin_permissions_on_admin_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_permissions_on_admin_role_id ON public.admin_permissions USING btree (admin_role_id);


--
-- TOC entry 6225 (class 1259 OID 96802)
-- Name: index_admin_roles_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_roles_on_discarded_at ON public.admin_roles USING btree (discarded_at);


--
-- TOC entry 6226 (class 1259 OID 96803)
-- Name: index_admin_roles_on_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_roles_on_name ON public.admin_roles USING btree (name);


--
-- TOC entry 6229 (class 1259 OID 96804)
-- Name: index_admin_slack_notification_logs_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_slack_notification_logs_on_admin_user_id ON public.admin_slack_notification_logs USING btree (admin_user_id);


--
-- TOC entry 6232 (class 1259 OID 96805)
-- Name: index_admin_user_col_pref_user_activities_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_user_col_pref_user_activities_on_admin_user_id ON public.admin_user_col_pref_user_activities USING btree (admin_user_id);


--
-- TOC entry 6235 (class 1259 OID 96806)
-- Name: index_admin_user_column_preferences_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_user_column_preferences_on_admin_user_id ON public.admin_user_column_preferences USING btree (admin_user_id);


--
-- TOC entry 6238 (class 1259 OID 96807)
-- Name: index_admin_user_customize_column_orders_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_user_customize_column_orders_on_admin_user_id ON public.admin_user_customize_column_orders USING btree (admin_user_id);


--
-- TOC entry 6242 (class 1259 OID 96808)
-- Name: index_admin_user_notifications_preferences_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_user_notifications_preferences_on_admin_user_id ON public.admin_user_notifications_preferences USING btree (admin_user_id);


--
-- TOC entry 6245 (class 1259 OID 96809)
-- Name: index_admin_user_smart_views_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_user_smart_views_on_admin_user_id ON public.admin_user_smart_views USING btree (admin_user_id);


--
-- TOC entry 6246 (class 1259 OID 96810)
-- Name: index_admin_user_smart_views_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_user_smart_views_on_discarded_at ON public.admin_user_smart_views USING btree (discarded_at);


--
-- TOC entry 6249 (class 1259 OID 96811)
-- Name: index_admin_users_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_users_on_discarded_at ON public.admin_users USING btree (discarded_at);


--
-- TOC entry 6250 (class 1259 OID 96812)
-- Name: index_admin_users_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_users_on_email ON public.admin_users USING btree (email);


--
-- TOC entry 6251 (class 1259 OID 96813)
-- Name: index_admin_users_on_manager_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_users_on_manager_id ON public.admin_users USING btree (manager_id);


--
-- TOC entry 6252 (class 1259 OID 96814)
-- Name: index_admin_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_admin_users_on_reset_password_token ON public.admin_users USING btree (reset_password_token);


--
-- TOC entry 6253 (class 1259 OID 96815)
-- Name: index_admin_users_on_team_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_admin_users_on_team_lead_id ON public.admin_users USING btree (team_lead_id);


--
-- TOC entry 6254 (class 1259 OID 96816)
-- Name: index_admin_users_on_unlock_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_admin_users_on_unlock_token ON public.admin_users USING btree (unlock_token);


--
-- TOC entry 6257 (class 1259 OID 96817)
-- Name: index_ads_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ads_on_account_id ON public.ads USING btree (account_id);


--
-- TOC entry 6258 (class 1259 OID 96818)
-- Name: index_ads_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ads_on_brand_id ON public.ads USING btree (brand_id);


--
-- TOC entry 6259 (class 1259 OID 96819)
-- Name: index_ads_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ads_on_discarded_at ON public.ads USING btree (discarded_at);


--
-- TOC entry 6262 (class 1259 OID 96820)
-- Name: index_agent_profiles_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_agent_profiles_on_account_id ON public.agent_profiles USING btree (account_id);


--
-- TOC entry 6263 (class 1259 OID 96821)
-- Name: index_agent_profiles_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_agent_profiles_on_brand_id ON public.agent_profiles USING btree (brand_id);


--
-- TOC entry 6266 (class 1259 OID 96822)
-- Name: index_ahoy_events_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ahoy_events_on_account_id ON public.ahoy_events USING btree (account_id);


--
-- TOC entry 6267 (class 1259 OID 96823)
-- Name: index_ahoy_events_on_name_and_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ahoy_events_on_name_and_time ON public.ahoy_events USING btree (name, "time");


--
-- TOC entry 6268 (class 1259 OID 96824)
-- Name: index_ahoy_events_on_properties; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ahoy_events_on_properties ON public.ahoy_events USING gin (properties jsonb_path_ops);


--
-- TOC entry 6269 (class 1259 OID 96825)
-- Name: index_ahoy_events_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ahoy_events_on_user_id ON public.ahoy_events USING btree (user_id);


--
-- TOC entry 6270 (class 1259 OID 96826)
-- Name: index_ahoy_events_on_visit_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ahoy_events_on_visit_id ON public.ahoy_events USING btree (visit_id);


--
-- TOC entry 6273 (class 1259 OID 96827)
-- Name: index_ahoy_visits_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ahoy_visits_on_user_id ON public.ahoy_visits USING btree (user_id);


--
-- TOC entry 6274 (class 1259 OID 96828)
-- Name: index_ahoy_visits_on_visit_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_ahoy_visits_on_visit_token ON public.ahoy_visits USING btree (visit_token);


--
-- TOC entry 6277 (class 1259 OID 96829)
-- Name: index_analytic_pixel_columns_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_analytic_pixel_columns_on_click_conversion_pixel_id ON public.analytic_pixel_columns USING btree (click_conversion_pixel_id);


--
-- TOC entry 6280 (class 1259 OID 96830)
-- Name: index_analytics_export_uploads_on_analytics_export_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_analytics_export_uploads_on_analytics_export_id ON public.analytics_export_uploads USING btree (analytics_export_id);


--
-- TOC entry 6283 (class 1259 OID 96831)
-- Name: index_analytics_exports_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_analytics_exports_on_account_id ON public.analytics_exports USING btree (account_id);


--
-- TOC entry 6284 (class 1259 OID 96832)
-- Name: index_analytics_exports_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_analytics_exports_on_admin_user_id ON public.analytics_exports USING btree (admin_user_id);


--
-- TOC entry 6285 (class 1259 OID 96833)
-- Name: index_analytics_exports_on_product_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_analytics_exports_on_product_type_id ON public.analytics_exports USING btree (product_type_id);


--
-- TOC entry 6286 (class 1259 OID 96834)
-- Name: index_analytics_exports_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_analytics_exports_on_user_id ON public.analytics_exports USING btree (user_id);


--
-- TOC entry 6291 (class 1259 OID 96835)
-- Name: index_api_timing_api_profiling_tags_on_api_profiling_tag_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_api_timing_api_profiling_tags_on_api_profiling_tag_id ON public.api_timing_api_profiling_tags USING btree (api_profiling_tag_id);


--
-- TOC entry 6292 (class 1259 OID 96836)
-- Name: index_api_timing_api_profiling_tags_on_api_timing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_api_timing_api_profiling_tags_on_api_timing_id ON public.api_timing_api_profiling_tags USING btree (api_timing_id);


--
-- TOC entry 6295 (class 1259 OID 96837)
-- Name: index_api_timings_on_api_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_api_timings_on_api_status ON public.api_timings USING btree (api_status);


--
-- TOC entry 6296 (class 1259 OID 96838)
-- Name: index_api_timings_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_api_timings_on_created_at ON public.api_timings USING btree (created_at);


--
-- TOC entry 6297 (class 1259 OID 96839)
-- Name: index_api_timings_on_elapsed_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_api_timings_on_elapsed_time ON public.api_timings USING btree (elapsed_time);


--
-- TOC entry 6302 (class 1259 OID 96840)
-- Name: index_assignments_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_assignments_on_discarded_at ON public.assignments USING btree (discarded_at);


--
-- TOC entry 6303 (class 1259 OID 96841)
-- Name: index_assignments_on_membership_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_assignments_on_membership_id ON public.assignments USING btree (membership_id);


--
-- TOC entry 6304 (class 1259 OID 96842)
-- Name: index_assignments_on_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_assignments_on_role_id ON public.assignments USING btree (role_id);


--
-- TOC entry 6307 (class 1259 OID 96843)
-- Name: index_ater_on_semaphore_workflow_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_ater_on_semaphore_workflow_id ON public.automation_test_execution_results USING btree (semaphore_workflow_id);


--
-- TOC entry 6311 (class 1259 OID 96844)
-- Name: index_atsr_on_ater_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_atsr_on_ater_id ON public.automation_test_suite_results USING btree (automation_test_execution_result_id);


--
-- TOC entry 6312 (class 1259 OID 96845)
-- Name: index_atsr_on_ater_id_and_suite_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_atsr_on_ater_id_and_suite_name ON public.automation_test_suite_results USING btree (automation_test_execution_result_id, test_suite_name);


--
-- TOC entry 6308 (class 1259 OID 96846)
-- Name: index_automation_test_execution_results_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_automation_test_execution_results_on_created_at ON public.automation_test_execution_results USING btree (created_at);


--
-- TOC entry 6315 (class 1259 OID 96847)
-- Name: index_bill_com_invoices_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_bill_com_invoices_on_account_id ON public.bill_com_invoices USING btree (account_id);


--
-- TOC entry 6316 (class 1259 OID 96848)
-- Name: index_bill_com_invoices_on_bill_com_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_bill_com_invoices_on_bill_com_id ON public.bill_com_invoices USING btree (bill_com_id);


--
-- TOC entry 6317 (class 1259 OID 96849)
-- Name: index_bill_com_invoices_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_bill_com_invoices_on_brand_id ON public.bill_com_invoices USING btree (brand_id);


--
-- TOC entry 6318 (class 1259 OID 96850)
-- Name: index_bill_com_invoices_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_bill_com_invoices_on_discarded_at ON public.bill_com_invoices USING btree (discarded_at);


--
-- TOC entry 6319 (class 1259 OID 96851)
-- Name: index_bill_com_invoices_on_due_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_bill_com_invoices_on_due_date ON public.bill_com_invoices USING btree (due_date);


--
-- TOC entry 6320 (class 1259 OID 96852)
-- Name: index_bill_com_invoices_on_invoice_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_bill_com_invoices_on_invoice_id ON public.bill_com_invoices USING btree (invoice_id);


--
-- TOC entry 6327 (class 1259 OID 96853)
-- Name: index_billing_setting_invoice_changes_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_billing_setting_invoice_changes_on_account_id ON public.billing_setting_invoice_changes USING btree (account_id);


--
-- TOC entry 6328 (class 1259 OID 96854)
-- Name: index_billing_setting_invoice_changes_on_billing_setting_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_billing_setting_invoice_changes_on_billing_setting_id ON public.billing_setting_invoice_changes USING btree (billing_setting_id);


--
-- TOC entry 6331 (class 1259 OID 96855)
-- Name: index_billing_settings_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_billing_settings_on_user_id ON public.billing_settings USING btree (user_id);


--
-- TOC entry 6334 (class 1259 OID 96856)
-- Name: index_brands_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_brands_on_account_id ON public.brands USING btree (account_id);


--
-- TOC entry 6335 (class 1259 OID 96857)
-- Name: index_brands_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_brands_on_discarded_at ON public.brands USING btree (discarded_at);


--
-- TOC entry 6338 (class 1259 OID 96858)
-- Name: index_call_ad_group_settings_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ad_group_settings_on_ad_group_id ON public.call_ad_group_settings USING btree (ad_group_id);


--
-- TOC entry 6339 (class 1259 OID 96859)
-- Name: index_call_ad_group_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ad_group_settings_on_discarded_at ON public.call_ad_group_settings USING btree (discarded_at);


--
-- TOC entry 6342 (class 1259 OID 96860)
-- Name: index_call_campaign_settings_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_campaign_settings_on_account_id ON public.call_campaign_settings USING btree (account_id);


--
-- TOC entry 6343 (class 1259 OID 96861)
-- Name: index_call_campaign_settings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_campaign_settings_on_campaign_id ON public.call_campaign_settings USING btree (campaign_id);


--
-- TOC entry 6344 (class 1259 OID 96862)
-- Name: index_call_campaign_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_campaign_settings_on_discarded_at ON public.call_campaign_settings USING btree (discarded_at);


--
-- TOC entry 6345 (class 1259 OID 96863)
-- Name: index_call_campaign_settings_on_tracking_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_campaign_settings_on_tracking_number ON public.call_campaign_settings USING btree (tracking_number);


--
-- TOC entry 6348 (class 1259 OID 96864)
-- Name: index_call_listings_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_listings_on_account_id ON public.call_listings USING btree (account_id);


--
-- TOC entry 6349 (class 1259 OID 96865)
-- Name: index_call_listings_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_listings_on_ad_group_id ON public.call_listings USING btree (ad_group_id);


--
-- TOC entry 6350 (class 1259 OID 96866)
-- Name: index_call_listings_on_bid_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_listings_on_bid_id ON public.call_listings USING btree (bid_id);


--
-- TOC entry 6351 (class 1259 OID 96867)
-- Name: index_call_listings_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_listings_on_brand_id ON public.call_listings USING btree (brand_id);


--
-- TOC entry 6352 (class 1259 OID 96868)
-- Name: index_call_listings_on_call_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_listings_on_call_ping_id ON public.call_listings USING btree (call_ping_id);


--
-- TOC entry 6353 (class 1259 OID 96869)
-- Name: index_call_listings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_listings_on_campaign_id ON public.call_listings USING btree (campaign_id);


--
-- TOC entry 6354 (class 1259 OID 96870)
-- Name: index_call_listings_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_listings_on_created_at ON public.call_listings USING btree (created_at);


--
-- TOC entry 6357 (class 1259 OID 96871)
-- Name: index_call_opportunities_on_call_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_opportunities_on_call_ping_id ON public.call_opportunities USING btree (call_ping_id);


--
-- TOC entry 6358 (class 1259 OID 96872)
-- Name: index_call_opportunities_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_opportunities_on_campaign_id ON public.call_opportunities USING btree (campaign_id);


--
-- TOC entry 6359 (class 1259 OID 96873)
-- Name: index_call_opportunities_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_opportunities_on_created_at ON public.call_opportunities USING btree (created_at);


--
-- TOC entry 6362 (class 1259 OID 96874)
-- Name: index_call_panels_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_panels_on_click_ping_id ON public.call_panels USING btree (click_ping_id);


--
-- TOC entry 6365 (class 1259 OID 96875)
-- Name: index_call_ping_debug_logs_on_call_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ping_debug_logs_on_call_ping_id ON public.call_ping_debug_logs USING btree (call_ping_id);


--
-- TOC entry 6368 (class 1259 OID 96876)
-- Name: index_call_ping_details_on_call_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ping_details_on_call_ping_id ON public.call_ping_details USING btree (call_ping_id);


--
-- TOC entry 6371 (class 1259 OID 96877)
-- Name: index_call_ping_matches_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ping_matches_on_account_id ON public.call_ping_matches USING btree (account_id);


--
-- TOC entry 6372 (class 1259 OID 96878)
-- Name: index_call_ping_matches_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ping_matches_on_ad_group_id ON public.call_ping_matches USING btree (ad_group_id);


--
-- TOC entry 6373 (class 1259 OID 96879)
-- Name: index_call_ping_matches_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ping_matches_on_brand_id ON public.call_ping_matches USING btree (brand_id);


--
-- TOC entry 6374 (class 1259 OID 96880)
-- Name: index_call_ping_matches_on_call_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ping_matches_on_call_ping_id ON public.call_ping_matches USING btree (call_ping_id);


--
-- TOC entry 6375 (class 1259 OID 96881)
-- Name: index_call_ping_matches_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_ping_matches_on_campaign_id ON public.call_ping_matches USING btree (campaign_id);


--
-- TOC entry 6378 (class 1259 OID 96882)
-- Name: index_call_pings_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_pings_on_created_at ON public.call_pings USING btree (created_at);


--
-- TOC entry 6379 (class 1259 OID 96883)
-- Name: index_call_pings_on_partner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_pings_on_partner_id ON public.call_pings USING btree (partner_id);


--
-- TOC entry 6380 (class 1259 OID 96884)
-- Name: index_call_pings_on_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_pings_on_uid ON public.call_pings USING btree (uid);


--
-- TOC entry 6383 (class 1259 OID 96885)
-- Name: index_call_post_details_on_call_post_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_post_details_on_call_post_id ON public.call_post_details USING btree (call_post_id);


--
-- TOC entry 6384 (class 1259 OID 96886)
-- Name: index_call_post_details_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_post_details_on_email ON public.call_post_details USING btree (email);


--
-- TOC entry 6385 (class 1259 OID 96887)
-- Name: index_call_post_details_on_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_post_details_on_phone ON public.call_post_details USING btree (phone);


--
-- TOC entry 6388 (class 1259 OID 96888)
-- Name: index_call_posts_on_call_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_posts_on_call_ping_id ON public.call_posts USING btree (call_ping_id);


--
-- TOC entry 6391 (class 1259 OID 96889)
-- Name: index_call_prices_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_call_prices_on_lead_type_id ON public.call_prices USING btree (lead_type_id);


--
-- TOC entry 6394 (class 1259 OID 96890)
-- Name: index_call_results_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_results_on_account_id ON public.call_results USING btree (account_id);


--
-- TOC entry 6395 (class 1259 OID 96891)
-- Name: index_call_results_on_call_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_results_on_call_ping_id ON public.call_results USING btree (call_ping_id);


--
-- TOC entry 6396 (class 1259 OID 96892)
-- Name: index_call_results_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_results_on_campaign_id ON public.call_results USING btree (campaign_id);


--
-- TOC entry 6399 (class 1259 OID 96893)
-- Name: index_call_transcription_rules_on_call_transcription_topic_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_transcription_rules_on_call_transcription_topic_id ON public.call_transcription_rules USING btree (call_transcription_topic_id);


--
-- TOC entry 6400 (class 1259 OID 96894)
-- Name: index_call_transcription_rules_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_transcription_rules_on_discarded_at ON public.call_transcription_rules USING btree (discarded_at);


--
-- TOC entry 6403 (class 1259 OID 96895)
-- Name: index_call_transcription_settings_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_transcription_settings_on_account_id ON public.call_transcription_settings USING btree (account_id);


--
-- TOC entry 6406 (class 1259 OID 96896)
-- Name: index_call_transcription_topics_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_transcription_topics_on_account_id ON public.call_transcription_topics USING btree (account_id);


--
-- TOC entry 6407 (class 1259 OID 96897)
-- Name: index_call_transcription_topics_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_call_transcription_topics_on_discarded_at ON public.call_transcription_topics USING btree (discarded_at);


--
-- TOC entry 6410 (class 1259 OID 96898)
-- Name: index_calls_customize_columns_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_calls_customize_columns_orders_on_user_id ON public.calls_customize_columns_orders USING btree (user_id);


--
-- TOC entry 6413 (class 1259 OID 96899)
-- Name: index_calls_dashboard_customize_column_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_calls_dashboard_customize_column_orders_on_user_id ON public.calls_dashboard_customize_column_orders USING btree (user_id);


--
-- TOC entry 6416 (class 1259 OID 96900)
-- Name: index_campaign_ads_on_ad_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_ads_on_ad_id ON public.campaign_ads USING btree (ad_id);


--
-- TOC entry 6417 (class 1259 OID 96901)
-- Name: index_campaign_ads_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_ads_on_campaign_id ON public.campaign_ads USING btree (campaign_id);


--
-- TOC entry 6418 (class 1259 OID 96902)
-- Name: index_campaign_ads_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_ads_on_discarded_at ON public.campaign_ads USING btree (discarded_at);


--
-- TOC entry 6421 (class 1259 OID 96903)
-- Name: index_campaign_bid_modifier_groups_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_bid_modifier_groups_on_campaign_id ON public.campaign_bid_modifier_groups USING btree (campaign_id);


--
-- TOC entry 6422 (class 1259 OID 96904)
-- Name: index_campaign_bid_modifier_groups_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_bid_modifier_groups_on_discarded_at ON public.campaign_bid_modifier_groups USING btree (discarded_at);


--
-- TOC entry 6425 (class 1259 OID 96905)
-- Name: index_campaign_bid_modifiers_on_campaign_bid_modifier_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_bid_modifiers_on_campaign_bid_modifier_group_id ON public.campaign_bid_modifiers USING btree (campaign_bid_modifier_group_id);


--
-- TOC entry 6426 (class 1259 OID 96906)
-- Name: index_campaign_bid_modifiers_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_bid_modifiers_on_campaign_id ON public.campaign_bid_modifiers USING btree (campaign_id);


--
-- TOC entry 6427 (class 1259 OID 96907)
-- Name: index_campaign_bid_modifiers_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_bid_modifiers_on_discarded_at ON public.campaign_bid_modifiers USING btree (discarded_at);


--
-- TOC entry 6428 (class 1259 OID 96908)
-- Name: index_campaign_bid_modifiers_on_sf_filter_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_bid_modifiers_on_sf_filter_id ON public.campaign_bid_modifiers USING btree (sf_filter_id);


--
-- TOC entry 6431 (class 1259 OID 96909)
-- Name: index_campaign_budgets_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_budgets_on_campaign_id ON public.campaign_budgets USING btree (campaign_id);


--
-- TOC entry 6432 (class 1259 OID 96910)
-- Name: index_campaign_budgets_on_day_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_budgets_on_day_id ON public.campaign_budgets USING btree (day_id);


--
-- TOC entry 6433 (class 1259 OID 96911)
-- Name: index_campaign_budgets_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_budgets_on_discarded_at ON public.campaign_budgets USING btree (discarded_at);


--
-- TOC entry 6436 (class 1259 OID 96912)
-- Name: index_campaign_call_posts_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_call_posts_on_account_id ON public.campaign_call_posts USING btree (account_id);


--
-- TOC entry 6437 (class 1259 OID 96913)
-- Name: index_campaign_call_posts_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_call_posts_on_brand_id ON public.campaign_call_posts USING btree (brand_id);


--
-- TOC entry 6438 (class 1259 OID 96914)
-- Name: index_campaign_call_posts_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_call_posts_on_campaign_id ON public.campaign_call_posts USING btree (campaign_id);


--
-- TOC entry 6439 (class 1259 OID 96915)
-- Name: index_campaign_call_posts_on_quote_call_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_call_posts_on_quote_call_id ON public.campaign_call_posts USING btree (quote_call_id);


--
-- TOC entry 6442 (class 1259 OID 96916)
-- Name: index_campaign_dashboard_colunm_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_dashboard_colunm_orders_on_user_id ON public.campaign_dashboard_colunm_orders USING btree (user_id);


--
-- TOC entry 6445 (class 1259 OID 96917)
-- Name: index_campaign_filter_groups_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filter_groups_on_campaign_id ON public.campaign_filter_groups USING btree (campaign_id);


--
-- TOC entry 6446 (class 1259 OID 96918)
-- Name: index_campaign_filter_groups_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filter_groups_on_discarded_at ON public.campaign_filter_groups USING btree (discarded_at);


--
-- TOC entry 6449 (class 1259 OID 96919)
-- Name: index_campaign_filter_packages_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filter_packages_on_campaign_id ON public.campaign_filter_packages USING btree (campaign_id);


--
-- TOC entry 6450 (class 1259 OID 96920)
-- Name: index_campaign_filter_packages_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filter_packages_on_discarded_at ON public.campaign_filter_packages USING btree (discarded_at);


--
-- TOC entry 6451 (class 1259 OID 96921)
-- Name: index_campaign_filter_packages_on_filter_package_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filter_packages_on_filter_package_id ON public.campaign_filter_packages USING btree (filter_package_id);


--
-- TOC entry 6454 (class 1259 OID 96922)
-- Name: index_campaign_filters_on_campaign_filter_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filters_on_campaign_filter_group_id ON public.campaign_filters USING btree (campaign_filter_group_id);


--
-- TOC entry 6455 (class 1259 OID 96923)
-- Name: index_campaign_filters_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filters_on_campaign_id ON public.campaign_filters USING btree (campaign_id);


--
-- TOC entry 6456 (class 1259 OID 96924)
-- Name: index_campaign_filters_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filters_on_discarded_at ON public.campaign_filters USING btree (discarded_at);


--
-- TOC entry 6457 (class 1259 OID 96925)
-- Name: index_campaign_filters_on_sf_filter_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_filters_on_sf_filter_id ON public.campaign_filters USING btree (sf_filter_id);


--
-- TOC entry 6460 (class 1259 OID 96926)
-- Name: index_campaign_lead_integrations_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_lead_integrations_on_campaign_id ON public.campaign_lead_integrations USING btree (campaign_id);


--
-- TOC entry 6461 (class 1259 OID 96927)
-- Name: index_campaign_lead_integrations_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_lead_integrations_on_discarded_at ON public.campaign_lead_integrations USING btree (discarded_at);


--
-- TOC entry 6462 (class 1259 OID 96928)
-- Name: index_campaign_lead_integrations_on_lead_integration_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_lead_integrations_on_lead_integration_id ON public.campaign_lead_integrations USING btree (lead_integration_id);


--
-- TOC entry 6465 (class 1259 OID 96929)
-- Name: index_campaign_lead_posts_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_lead_posts_on_account_id ON public.campaign_lead_posts USING btree (account_id);


--
-- TOC entry 6466 (class 1259 OID 96930)
-- Name: index_campaign_lead_posts_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_lead_posts_on_brand_id ON public.campaign_lead_posts USING btree (brand_id);


--
-- TOC entry 6467 (class 1259 OID 96931)
-- Name: index_campaign_lead_posts_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_lead_posts_on_campaign_id ON public.campaign_lead_posts USING btree (campaign_id);


--
-- TOC entry 6470 (class 1259 OID 96932)
-- Name: index_campaign_monthly_spends_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_monthly_spends_on_account_id ON public.campaign_monthly_spends USING btree (account_id);


--
-- TOC entry 6471 (class 1259 OID 96933)
-- Name: index_campaign_monthly_spends_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_monthly_spends_on_campaign_id ON public.campaign_monthly_spends USING btree (campaign_id);


--
-- TOC entry 6472 (class 1259 OID 96934)
-- Name: index_campaign_monthly_spends_on_campaign_id_and_year_and_month; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_campaign_monthly_spends_on_campaign_id_and_year_and_month ON public.campaign_monthly_spends USING btree (campaign_id, year, month);


--
-- TOC entry 6475 (class 1259 OID 96935)
-- Name: index_campaign_notes_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_notes_on_admin_user_id ON public.campaign_notes USING btree (admin_user_id);


--
-- TOC entry 6476 (class 1259 OID 96936)
-- Name: index_campaign_notes_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_notes_on_campaign_id ON public.campaign_notes USING btree (campaign_id);


--
-- TOC entry 6477 (class 1259 OID 96937)
-- Name: index_campaign_notes_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_notes_on_discarded_at ON public.campaign_notes USING btree (discarded_at);


--
-- TOC entry 6480 (class 1259 OID 96938)
-- Name: index_campaign_pixel_columns_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_pixel_columns_on_click_conversion_pixel_id ON public.campaign_pixel_columns USING btree (click_conversion_pixel_id);


--
-- TOC entry 6483 (class 1259 OID 96939)
-- Name: index_campaign_quote_funnels_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_quote_funnels_on_campaign_id ON public.campaign_quote_funnels USING btree (campaign_id);


--
-- TOC entry 6484 (class 1259 OID 96940)
-- Name: index_campaign_quote_funnels_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_quote_funnels_on_discarded_at ON public.campaign_quote_funnels USING btree (discarded_at);


--
-- TOC entry 6485 (class 1259 OID 96941)
-- Name: index_campaign_quote_funnels_on_quote_funnel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_quote_funnels_on_quote_funnel_id ON public.campaign_quote_funnels USING btree (quote_funnel_id);


--
-- TOC entry 6488 (class 1259 OID 96942)
-- Name: index_campaign_schedules_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_schedules_on_campaign_id ON public.campaign_schedules USING btree (campaign_id);


--
-- TOC entry 6489 (class 1259 OID 96943)
-- Name: index_campaign_schedules_on_day_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_schedules_on_day_id ON public.campaign_schedules USING btree (day_id);


--
-- TOC entry 6490 (class 1259 OID 96944)
-- Name: index_campaign_schedules_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_schedules_on_discarded_at ON public.campaign_schedules USING btree (discarded_at);


--
-- TOC entry 6493 (class 1259 OID 96945)
-- Name: index_campaign_source_settings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_source_settings_on_campaign_id ON public.campaign_source_settings USING btree (campaign_id);


--
-- TOC entry 6494 (class 1259 OID 96946)
-- Name: index_campaign_source_settings_on_source_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_source_settings_on_source_type_id ON public.campaign_source_settings USING btree (source_type_id);


--
-- TOC entry 6498 (class 1259 OID 96947)
-- Name: index_campaign_spends_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_spends_on_campaign_id ON public.campaign_spends USING btree (campaign_id);


--
-- TOC entry 6499 (class 1259 OID 96948)
-- Name: index_campaign_spends_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_spends_on_discarded_at ON public.campaign_spends USING btree (discarded_at);


--
-- TOC entry 6500 (class 1259 OID 96949)
-- Name: index_campaign_spends_on_dt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_spends_on_dt ON public.campaign_spends USING btree (dt);


--
-- TOC entry 6501 (class 1259 OID 96950)
-- Name: index_campaign_spends_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaign_spends_on_user_id ON public.campaign_spends USING btree (user_id);


--
-- TOC entry 6495 (class 1259 OID 96951)
-- Name: index_campaign_src_settings_on_cmp_id_src_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_campaign_src_settings_on_cmp_id_src_id ON public.campaign_source_settings USING btree (campaign_id, source_type_id);


--
-- TOC entry 6513 (class 1259 OID 96952)
-- Name: index_campaigns_customize_columns_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaigns_customize_columns_orders_on_user_id ON public.campaigns_customize_columns_orders USING btree (user_id);


--
-- TOC entry 6505 (class 1259 OID 96953)
-- Name: index_campaigns_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaigns_on_account_id ON public.campaigns USING btree (account_id);


--
-- TOC entry 6506 (class 1259 OID 96954)
-- Name: index_campaigns_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaigns_on_brand_id ON public.campaigns USING btree (brand_id);


--
-- TOC entry 6507 (class 1259 OID 96955)
-- Name: index_campaigns_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaigns_on_discarded_at ON public.campaigns USING btree (discarded_at);


--
-- TOC entry 6508 (class 1259 OID 96956)
-- Name: index_campaigns_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaigns_on_lead_type_id ON public.campaigns USING btree (lead_type_id);


--
-- TOC entry 6509 (class 1259 OID 96957)
-- Name: index_campaigns_on_product_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaigns_on_product_type_id ON public.campaigns USING btree (product_type_id);


--
-- TOC entry 6510 (class 1259 OID 96958)
-- Name: index_campaigns_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_campaigns_on_user_id ON public.campaigns USING btree (user_id);


--
-- TOC entry 6516 (class 1259 OID 96959)
-- Name: index_ccpa_opted_out_users_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ccpa_opted_out_users_on_email ON public.ccpa_opted_out_users USING btree (email);


--
-- TOC entry 6517 (class 1259 OID 96960)
-- Name: index_ccpa_opted_out_users_on_email_and_phone_num; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ccpa_opted_out_users_on_email_and_phone_num ON public.ccpa_opted_out_users USING btree (email, phone_num);


--
-- TOC entry 6518 (class 1259 OID 96961)
-- Name: index_ccpa_opted_out_users_on_phone_num; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_ccpa_opted_out_users_on_phone_num ON public.ccpa_opted_out_users USING btree (phone_num);


--
-- TOC entry 6521 (class 1259 OID 96962)
-- Name: index_click_ad_group_settings_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ad_group_settings_on_ad_group_id ON public.click_ad_group_settings USING btree (ad_group_id);


--
-- TOC entry 6522 (class 1259 OID 96963)
-- Name: index_click_ad_group_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ad_group_settings_on_discarded_at ON public.click_ad_group_settings USING btree (discarded_at);


--
-- TOC entry 6525 (class 1259 OID 96964)
-- Name: index_click_campaign_settings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_click_campaign_settings_on_campaign_id ON public.click_campaign_settings USING btree (campaign_id);


--
-- TOC entry 6526 (class 1259 OID 96965)
-- Name: index_click_campaign_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_campaign_settings_on_discarded_at ON public.click_campaign_settings USING btree (discarded_at);


--
-- TOC entry 6529 (class 1259 OID 96966)
-- Name: index_click_conversion_errors_on_caller_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_errors_on_caller_id ON public.click_conversion_errors USING btree (caller_id);


--
-- TOC entry 6530 (class 1259 OID 96967)
-- Name: index_click_conversion_errors_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_errors_on_click_conversion_pixel_id ON public.click_conversion_errors USING btree (click_conversion_pixel_id);


--
-- TOC entry 6531 (class 1259 OID 96968)
-- Name: index_click_conversion_errors_on_click_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_errors_on_click_id ON public.click_conversion_errors USING btree (click_id);


--
-- TOC entry 6532 (class 1259 OID 96969)
-- Name: index_click_conversion_errors_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_errors_on_lead_id ON public.click_conversion_errors USING btree (lead_id);


--
-- TOC entry 6535 (class 1259 OID 96970)
-- Name: index_click_conversion_log_details_on_click_conversion_log_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_log_details_on_click_conversion_log_id ON public.click_conversion_log_details USING btree (click_conversion_log_id);


--
-- TOC entry 6536 (class 1259 OID 96971)
-- Name: index_click_conversion_log_details_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_log_details_on_click_conversion_pixel_id ON public.click_conversion_log_details USING btree (click_conversion_pixel_id);


--
-- TOC entry 6539 (class 1259 OID 96972)
-- Name: index_click_conversion_logs_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_logs_on_account_id ON public.click_conversion_logs USING btree (account_id);


--
-- TOC entry 6540 (class 1259 OID 96973)
-- Name: index_click_conversion_logs_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_logs_on_brand_id ON public.click_conversion_logs USING btree (brand_id);


--
-- TOC entry 6541 (class 1259 OID 96974)
-- Name: index_click_conversion_logs_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_logs_on_discarded_at ON public.click_conversion_logs USING btree (discarded_at);


--
-- TOC entry 6542 (class 1259 OID 96975)
-- Name: index_click_conversion_logs_on_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_logs_on_token ON public.click_conversion_logs USING btree (token);


--
-- TOC entry 6543 (class 1259 OID 96976)
-- Name: index_click_conversion_logs_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_logs_on_user_id ON public.click_conversion_logs USING btree (user_id);


--
-- TOC entry 6546 (class 1259 OID 96977)
-- Name: index_click_conversion_pixels_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_pixels_on_account_id ON public.click_conversion_pixels USING btree (account_id);


--
-- TOC entry 6547 (class 1259 OID 96978)
-- Name: index_click_conversion_pixels_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_pixels_on_brand_id ON public.click_conversion_pixels USING btree (brand_id);


--
-- TOC entry 6548 (class 1259 OID 96979)
-- Name: index_click_conversion_pixels_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversion_pixels_on_discarded_at ON public.click_conversion_pixels USING btree (discarded_at);


--
-- TOC entry 6551 (class 1259 OID 96980)
-- Name: index_click_conversions_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_account_id ON public.click_conversions USING btree (account_id);


--
-- TOC entry 6552 (class 1259 OID 96981)
-- Name: index_click_conversions_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_brand_id ON public.click_conversions USING btree (brand_id);


--
-- TOC entry 6553 (class 1259 OID 96982)
-- Name: index_click_conversions_on_call_listing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_call_listing_id ON public.click_conversions USING btree (call_listing_id);


--
-- TOC entry 6554 (class 1259 OID 96983)
-- Name: index_click_conversions_on_caller_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_caller_id ON public.click_conversions USING btree (caller_id);


--
-- TOC entry 6555 (class 1259 OID 96984)
-- Name: index_click_conversions_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_campaign_id ON public.click_conversions USING btree (campaign_id);


--
-- TOC entry 6556 (class 1259 OID 96985)
-- Name: index_click_conversions_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_click_conversion_pixel_id ON public.click_conversions USING btree (click_conversion_pixel_id);


--
-- TOC entry 6557 (class 1259 OID 96986)
-- Name: index_click_conversions_on_click_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_click_id ON public.click_conversions USING btree (click_id);


--
-- TOC entry 6558 (class 1259 OID 96987)
-- Name: index_click_conversions_on_click_listing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_click_listing_id ON public.click_conversions USING btree (click_listing_id);


--
-- TOC entry 6559 (class 1259 OID 96988)
-- Name: index_click_conversions_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_discarded_at ON public.click_conversions USING btree (discarded_at);


--
-- TOC entry 6560 (class 1259 OID 96989)
-- Name: index_click_conversions_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_lead_id ON public.click_conversions USING btree (lead_id);


--
-- TOC entry 6561 (class 1259 OID 96990)
-- Name: index_click_conversions_on_lead_listing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_lead_listing_id ON public.click_conversions USING btree (lead_listing_id);


--
-- TOC entry 6562 (class 1259 OID 96991)
-- Name: index_click_conversions_on_listing_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_listing_created_at ON public.click_conversions USING btree (listing_created_at);


--
-- TOC entry 6563 (class 1259 OID 96992)
-- Name: index_click_conversions_on_product_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_product_type_id ON public.click_conversions USING btree (product_type_id);


--
-- TOC entry 6564 (class 1259 OID 96993)
-- Name: index_click_conversions_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_conversions_on_updated_at ON public.click_conversions USING btree (updated_at);


--
-- TOC entry 6567 (class 1259 OID 96994)
-- Name: index_click_integration_logs_on_click_integration_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_integration_logs_on_click_integration_id ON public.click_integration_logs USING btree (click_integration_id);


--
-- TOC entry 6572 (class 1259 OID 96995)
-- Name: index_click_integrations_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_integrations_on_account_id ON public.click_integrations USING btree (account_id);


--
-- TOC entry 6575 (class 1259 OID 96996)
-- Name: index_click_listings_on_account_id_and_brand_id_and_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_account_id_and_brand_id_and_campaign_id ON public.click_listings USING btree (account_id, brand_id, campaign_id);


--
-- TOC entry 6576 (class 1259 OID 96997)
-- Name: index_click_listings_on_account_id_and_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_account_id_and_campaign_id ON public.click_listings USING btree (account_id, campaign_id);


--
-- TOC entry 6577 (class 1259 OID 96998)
-- Name: index_click_listings_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_ad_group_id ON public.click_listings USING btree (ad_group_id);


--
-- TOC entry 6578 (class 1259 OID 96999)
-- Name: index_click_listings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_campaign_id ON public.click_listings USING btree (campaign_id);


--
-- TOC entry 6579 (class 1259 OID 97000)
-- Name: index_click_listings_on_click_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_click_id ON public.click_listings USING btree (click_id);


--
-- TOC entry 6580 (class 1259 OID 97001)
-- Name: index_click_listings_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_click_ping_id ON public.click_listings USING btree (click_ping_id);


--
-- TOC entry 6581 (class 1259 OID 97002)
-- Name: index_click_listings_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_created_at ON public.click_listings USING btree (created_at);


--
-- TOC entry 6582 (class 1259 OID 97003)
-- Name: index_click_listings_on_created_at_acc_id_brnd_id_cmp_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_created_at_acc_id_brnd_id_cmp_id ON public.click_listings USING btree (created_at, account_id, brand_id, campaign_id);


--
-- TOC entry 6583 (class 1259 OID 97004)
-- Name: index_click_listings_on_created_at_and_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_created_at_and_campaign_id ON public.click_listings USING btree (created_at, campaign_id);


--
-- TOC entry 6584 (class 1259 OID 97005)
-- Name: index_click_listings_on_pp_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_listings_on_pp_ping_id ON public.click_listings USING btree (pp_ping_id);


--
-- TOC entry 6587 (class 1259 OID 97006)
-- Name: index_click_opportunities_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_account_id ON public.click_opportunities USING btree (account_id);


--
-- TOC entry 6588 (class 1259 OID 97007)
-- Name: index_click_opportunities_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_ad_group_id ON public.click_opportunities USING btree (ad_group_id);


--
-- TOC entry 6589 (class 1259 OID 97008)
-- Name: index_click_opportunities_on_ad_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_ad_id ON public.click_opportunities USING btree (ad_id);


--
-- TOC entry 6590 (class 1259 OID 97009)
-- Name: index_click_opportunities_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_brand_id ON public.click_opportunities USING btree (brand_id);


--
-- TOC entry 6591 (class 1259 OID 97010)
-- Name: index_click_opportunities_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_campaign_id ON public.click_opportunities USING btree (campaign_id);


--
-- TOC entry 6592 (class 1259 OID 97011)
-- Name: index_click_opportunities_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_click_ping_id ON public.click_opportunities USING btree (click_ping_id);


--
-- TOC entry 6593 (class 1259 OID 97012)
-- Name: index_click_opportunities_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_created_at ON public.click_opportunities USING btree (created_at);


--
-- TOC entry 6594 (class 1259 OID 97013)
-- Name: index_click_opportunities_on_created_at_and_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_created_at_and_account_id ON public.click_opportunities USING btree (created_at, account_id);


--
-- TOC entry 6595 (class 1259 OID 97014)
-- Name: index_click_opportunities_on_created_at_and_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_created_at_and_ad_group_id ON public.click_opportunities USING btree (created_at, ad_group_id);


--
-- TOC entry 6596 (class 1259 OID 97015)
-- Name: index_click_opportunities_on_created_at_and_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_created_at_and_brand_id ON public.click_opportunities USING btree (created_at, brand_id);


--
-- TOC entry 6597 (class 1259 OID 97016)
-- Name: index_click_opportunities_on_created_at_and_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_opportunities_on_created_at_and_campaign_id ON public.click_opportunities USING btree (created_at, campaign_id);


--
-- TOC entry 6600 (class 1259 OID 97017)
-- Name: index_click_panels_on_advertiser; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_panels_on_advertiser ON public.click_panels USING btree (advertiser);


--
-- TOC entry 6601 (class 1259 OID 97018)
-- Name: index_click_panels_on_click_listing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_panels_on_click_listing_id ON public.click_panels USING btree (click_listing_id);


--
-- TOC entry 6602 (class 1259 OID 97019)
-- Name: index_click_panels_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_panels_on_click_ping_id ON public.click_panels USING btree (click_ping_id);


--
-- TOC entry 6605 (class 1259 OID 97020)
-- Name: index_click_ping_debug_logs_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_debug_logs_on_click_ping_id ON public.click_ping_debug_logs USING btree (click_ping_id);


--
-- TOC entry 6608 (class 1259 OID 97021)
-- Name: index_click_ping_details_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_details_on_click_ping_id ON public.click_ping_details USING btree (click_ping_id);


--
-- TOC entry 6609 (class 1259 OID 97022)
-- Name: index_click_ping_details_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_details_on_created_at ON public.click_ping_details USING btree (created_at);


--
-- TOC entry 6610 (class 1259 OID 97023)
-- Name: index_click_ping_details_on_ip_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_details_on_ip_address ON public.click_ping_details USING btree (ip_address);


--
-- TOC entry 6611 (class 1259 OID 97024)
-- Name: index_click_ping_details_on_ip_address_and_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_details_on_ip_address_and_id ON public.click_ping_details USING btree (ip_address, id);


--
-- TOC entry 6612 (class 1259 OID 97025)
-- Name: index_click_ping_details_on_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_details_on_phone ON public.click_ping_details USING btree (phone);


--
-- TOC entry 6615 (class 1259 OID 97026)
-- Name: index_click_ping_matches_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_matches_on_account_id ON public.click_ping_matches USING btree (account_id);


--
-- TOC entry 6616 (class 1259 OID 97027)
-- Name: index_click_ping_matches_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_matches_on_ad_group_id ON public.click_ping_matches USING btree (ad_group_id);


--
-- TOC entry 6617 (class 1259 OID 97028)
-- Name: index_click_ping_matches_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_matches_on_brand_id ON public.click_ping_matches USING btree (brand_id);


--
-- TOC entry 6618 (class 1259 OID 97029)
-- Name: index_click_ping_matches_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_matches_on_campaign_id ON public.click_ping_matches USING btree (campaign_id);


--
-- TOC entry 6619 (class 1259 OID 97030)
-- Name: index_click_ping_matches_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_matches_on_click_ping_id ON public.click_ping_matches USING btree (click_ping_id);


--
-- TOC entry 6622 (class 1259 OID 97031)
-- Name: index_click_ping_vals_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_ping_vals_on_click_ping_id ON public.click_ping_vals USING btree (click_ping_id);


--
-- TOC entry 6625 (class 1259 OID 97032)
-- Name: index_click_pings_on_aid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_aid ON public.click_pings USING btree (aid);


--
-- TOC entry 6626 (class 1259 OID 97033)
-- Name: index_click_pings_on_cid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_cid ON public.click_pings USING btree (cid);


--
-- TOC entry 6627 (class 1259 OID 97034)
-- Name: index_click_pings_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_created_at ON public.click_pings USING btree (created_at);


--
-- TOC entry 6628 (class 1259 OID 97035)
-- Name: index_click_pings_on_device_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_device_type ON public.click_pings USING gin (device_type);


--
-- TOC entry 6629 (class 1259 OID 97036)
-- Name: index_click_pings_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_lead_type_id ON public.click_pings USING btree (lead_type_id);


--
-- TOC entry 6630 (class 1259 OID 97037)
-- Name: index_click_pings_on_partner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_partner_id ON public.click_pings USING btree (partner_id);


--
-- TOC entry 6631 (class 1259 OID 97038)
-- Name: index_click_pings_on_state; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_state ON public.click_pings USING btree (state);


--
-- TOC entry 6632 (class 1259 OID 97039)
-- Name: index_click_pings_on_zip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_pings_on_zip ON public.click_pings USING btree (zip);


--
-- TOC entry 6635 (class 1259 OID 97040)
-- Name: index_click_posts_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_posts_on_campaign_id ON public.click_posts USING btree (campaign_id);


--
-- TOC entry 6636 (class 1259 OID 97041)
-- Name: index_click_posts_on_click_listing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_posts_on_click_listing_id ON public.click_posts USING btree (click_listing_id);


--
-- TOC entry 6637 (class 1259 OID 97042)
-- Name: index_click_posts_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_posts_on_click_ping_id ON public.click_posts USING btree (click_ping_id);


--
-- TOC entry 6640 (class 1259 OID 97043)
-- Name: index_click_receipts_on_click_listing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_receipts_on_click_listing_id ON public.click_receipts USING btree (click_listing_id);


--
-- TOC entry 6641 (class 1259 OID 97044)
-- Name: index_click_receipts_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_receipts_on_created_at ON public.click_receipts USING btree (created_at);


--
-- TOC entry 6642 (class 1259 OID 97045)
-- Name: index_click_receipts_on_ip_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_receipts_on_ip_address ON public.click_receipts USING btree (ip_address);


--
-- TOC entry 6648 (class 1259 OID 97046)
-- Name: index_click_results_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_results_on_account_id ON public.click_results USING btree (account_id);


--
-- TOC entry 6649 (class 1259 OID 97047)
-- Name: index_click_results_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_click_results_on_click_ping_id ON public.click_results USING btree (click_ping_id);


--
-- TOC entry 6652 (class 1259 OID 97048)
-- Name: index_clicks_dashboard_customize_column_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_clicks_dashboard_customize_column_orders_on_user_id ON public.clicks_dashboard_customize_column_orders USING btree (user_id);


--
-- TOC entry 6655 (class 1259 OID 97049)
-- Name: index_close_com_items_on_dbfkey_itype_cotypeid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_close_com_items_on_dbfkey_itype_cotypeid ON public.close_com_items USING btree (db_field_key, item_type, cotype_id);


--
-- TOC entry 6656 (class 1259 OID 97050)
-- Name: index_close_com_items_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_close_com_items_on_discarded_at ON public.close_com_items USING btree (discarded_at);


--
-- TOC entry 6657 (class 1259 OID 97051)
-- Name: index_close_com_items_on_item_type_and_label; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_close_com_items_on_item_type_and_label ON public.close_com_items USING btree (item_type, label);


--
-- TOC entry 6658 (class 1259 OID 97052)
-- Name: index_close_com_items_on_label; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_close_com_items_on_label ON public.close_com_items USING btree (label);


--
-- TOC entry 6661 (class 1259 OID 97053)
-- Name: index_conversion_log_transactions_on_click_conversion_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_conversion_log_transactions_on_click_conversion_id ON public.conversion_log_transactions USING btree (click_conversion_id);


--
-- TOC entry 6662 (class 1259 OID 97054)
-- Name: index_conversion_log_transactions_on_click_conversion_log_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_conversion_log_transactions_on_click_conversion_log_id ON public.conversion_log_transactions USING btree (click_conversion_log_id);


--
-- TOC entry 6663 (class 1259 OID 97055)
-- Name: index_conversion_log_transactions_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_conversion_log_transactions_on_discarded_at ON public.conversion_log_transactions USING btree (discarded_at);


--
-- TOC entry 6664 (class 1259 OID 97056)
-- Name: index_conversion_log_transactions_on_event; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_conversion_log_transactions_on_event ON public.conversion_log_transactions USING btree (event);


--
-- TOC entry 6667 (class 1259 OID 97057)
-- Name: index_conversions_logs_pixel_cols_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_conversions_logs_pixel_cols_on_click_conversion_pixel_id ON public.conversions_logs_pixel_cols USING btree (click_conversion_pixel_id);


--
-- TOC entry 6670 (class 1259 OID 97058)
-- Name: index_custom_intermediate_integration_configs_on_config_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_custom_intermediate_integration_configs_on_config_id ON public.custom_intermediate_integration_configs USING btree (config_id);


--
-- TOC entry 6671 (class 1259 OID 97059)
-- Name: index_custom_intermediate_integration_configs_on_config_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_custom_intermediate_integration_configs_on_config_type ON public.custom_intermediate_integration_configs USING btree (config_type);


--
-- TOC entry 6674 (class 1259 OID 97060)
-- Name: index_customize_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_customize_orders_on_user_id ON public.customize_orders USING btree (user_id);


--
-- TOC entry 6679 (class 1259 OID 97061)
-- Name: index_dms_logs_on_log_stream; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_dms_logs_on_log_stream ON public.dms_logs USING btree (log_stream);


--
-- TOC entry 6680 (class 1259 OID 97062)
-- Name: index_dms_logs_on_message_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_dms_logs_on_message_type ON public.dms_logs USING btree (message_type);


--
-- TOC entry 6681 (class 1259 OID 97063)
-- Name: index_dms_logs_on_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_dms_logs_on_timestamp ON public.dms_logs USING btree ("timestamp");


--
-- TOC entry 6686 (class 1259 OID 97064)
-- Name: index_email_export_logs_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_email_export_logs_on_account_id ON public.email_export_logs USING btree (account_id);


--
-- TOC entry 6687 (class 1259 OID 97065)
-- Name: index_email_export_logs_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_email_export_logs_on_admin_user_id ON public.email_export_logs USING btree (admin_user_id);


--
-- TOC entry 6688 (class 1259 OID 97066)
-- Name: index_email_export_logs_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_email_export_logs_on_user_id ON public.email_export_logs USING btree (user_id);


--
-- TOC entry 6695 (class 1259 OID 97067)
-- Name: index_features_on_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_features_on_name ON public.features USING btree (name);


--
-- TOC entry 6698 (class 1259 OID 97068)
-- Name: index_filter_package_filters_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_filter_package_filters_on_discarded_at ON public.filter_package_filters USING btree (discarded_at);


--
-- TOC entry 6699 (class 1259 OID 97069)
-- Name: index_filter_package_filters_on_filter_package_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_filter_package_filters_on_filter_package_id ON public.filter_package_filters USING btree (filter_package_id);


--
-- TOC entry 6700 (class 1259 OID 97070)
-- Name: index_filter_package_filters_on_sf_filter_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_filter_package_filters_on_sf_filter_id ON public.filter_package_filters USING btree (sf_filter_id);


--
-- TOC entry 6703 (class 1259 OID 97071)
-- Name: index_filter_packages_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_filter_packages_on_discarded_at ON public.filter_packages USING btree (discarded_at);


--
-- TOC entry 6706 (class 1259 OID 97072)
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- TOC entry 6709 (class 1259 OID 97073)
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- TOC entry 6712 (class 1259 OID 97074)
-- Name: index_history_versions_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_account_id ON public.history_versions USING btree (account_id);


--
-- TOC entry 6713 (class 1259 OID 97075)
-- Name: index_history_versions_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_admin_user_id ON public.history_versions USING btree (admin_user_id);


--
-- TOC entry 6714 (class 1259 OID 97076)
-- Name: index_history_versions_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_brand_id ON public.history_versions USING btree (brand_id);


--
-- TOC entry 6715 (class 1259 OID 97077)
-- Name: index_history_versions_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_campaign_id ON public.history_versions USING btree (campaign_id);


--
-- TOC entry 6716 (class 1259 OID 97078)
-- Name: index_history_versions_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_created_at ON public.history_versions USING btree (created_at);


--
-- TOC entry 6717 (class 1259 OID 97079)
-- Name: index_history_versions_on_created_at_and_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_created_at_and_account_id ON public.history_versions USING btree (created_at, account_id);


--
-- TOC entry 6718 (class 1259 OID 97080)
-- Name: index_history_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_item_type_and_item_id ON public.history_versions USING btree (item_type, item_id);


--
-- TOC entry 6719 (class 1259 OID 97081)
-- Name: index_history_versions_on_parent_id_and_parent_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_parent_id_and_parent_type ON public.history_versions USING btree (parent_id, parent_type);


--
-- TOC entry 6720 (class 1259 OID 97082)
-- Name: index_history_versions_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_user_id ON public.history_versions USING btree (user_id);


--
-- TOC entry 6721 (class 1259 OID 97083)
-- Name: index_history_versions_on_version_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_history_versions_on_version_id ON public.history_versions USING btree (version_id);


--
-- TOC entry 6722 (class 1259 OID 97084)
-- Name: index_insurance_carriers_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_insurance_carriers_on_discarded_at ON public.insurance_carriers USING btree (discarded_at);


--
-- TOC entry 6729 (class 1259 OID 97085)
-- Name: index_invoice_raw_stats_on_invoice_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_invoice_raw_stats_on_invoice_id ON public.invoice_raw_stats USING btree (invoice_id);


--
-- TOC entry 6732 (class 1259 OID 97086)
-- Name: index_invoices_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_invoices_on_account_id ON public.invoices USING btree (account_id);


--
-- TOC entry 6733 (class 1259 OID 97087)
-- Name: index_invoices_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_invoices_on_brand_id ON public.invoices USING btree (brand_id);


--
-- TOC entry 6734 (class 1259 OID 97088)
-- Name: index_invoices_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_invoices_on_discarded_at ON public.invoices USING btree (discarded_at);


--
-- TOC entry 6735 (class 1259 OID 97089)
-- Name: index_invoices_on_payment_term_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_invoices_on_payment_term_id ON public.invoices USING btree (payment_term_id);


--
-- TOC entry 6740 (class 1259 OID 97090)
-- Name: index_jwt_denylist_on_jti; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_jwt_denylist_on_jti ON public.jwt_denylist USING btree (jti);


--
-- TOC entry 6743 (class 1259 OID 97091)
-- Name: index_lead_applicants_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_applicants_on_discarded_at ON public.lead_applicants USING btree (discarded_at);


--
-- TOC entry 6744 (class 1259 OID 97092)
-- Name: index_lead_applicants_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_applicants_on_lead_id ON public.lead_applicants USING btree (lead_id);


--
-- TOC entry 6745 (class 1259 OID 97093)
-- Name: index_lead_applicants_on_marital_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_applicants_on_marital_status ON public.lead_applicants USING btree (marital_status);


--
-- TOC entry 6748 (class 1259 OID 97094)
-- Name: index_lead_business_entities_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_business_entities_on_discarded_at ON public.lead_business_entities USING btree (discarded_at);


--
-- TOC entry 6749 (class 1259 OID 97095)
-- Name: index_lead_business_entities_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_business_entities_on_lead_id ON public.lead_business_entities USING btree (lead_id);


--
-- TOC entry 6752 (class 1259 OID 97096)
-- Name: index_lead_campaign_settings_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_campaign_settings_on_account_id ON public.lead_campaign_settings USING btree (account_id);


--
-- TOC entry 6753 (class 1259 OID 97097)
-- Name: index_lead_campaign_settings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_campaign_settings_on_campaign_id ON public.lead_campaign_settings USING btree (campaign_id);


--
-- TOC entry 6754 (class 1259 OID 97098)
-- Name: index_lead_campaign_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_campaign_settings_on_discarded_at ON public.lead_campaign_settings USING btree (discarded_at);


--
-- TOC entry 6757 (class 1259 OID 97099)
-- Name: index_lead_details_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_details_on_created_at ON public.lead_details USING btree (created_at);


--
-- TOC entry 6758 (class 1259 OID 97100)
-- Name: index_lead_details_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_details_on_email ON public.lead_details USING btree (email);


--
-- TOC entry 6759 (class 1259 OID 97101)
-- Name: index_lead_details_on_jornaya_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_details_on_jornaya_lead_id ON public.lead_details USING btree (jornaya_lead_id);


--
-- TOC entry 6760 (class 1259 OID 97102)
-- Name: index_lead_details_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_details_on_lead_id ON public.lead_details USING btree (lead_id);


--
-- TOC entry 6761 (class 1259 OID 97103)
-- Name: index_lead_details_on_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_details_on_phone ON public.lead_details USING btree (phone);


--
-- TOC entry 6764 (class 1259 OID 97104)
-- Name: index_lead_homes_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_homes_on_discarded_at ON public.lead_homes USING btree (discarded_at);


--
-- TOC entry 6765 (class 1259 OID 97105)
-- Name: index_lead_homes_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_homes_on_lead_id ON public.lead_homes USING btree (lead_id);


--
-- TOC entry 6768 (class 1259 OID 97106)
-- Name: index_lead_integration_failure_reasons_on_lead_integration_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_failure_reasons_on_lead_integration_id ON public.lead_integration_failure_reasons USING btree (lead_integration_id);


--
-- TOC entry 6771 (class 1259 OID 97107)
-- Name: index_lead_integration_macro_mapping_on_macro; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_macro_mapping_on_macro ON public.lead_integration_macro_mappings USING btree (lead_integration_macro_id);


--
-- TOC entry 6772 (class 1259 OID 97108)
-- Name: index_lead_integration_macro_mappings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_macro_mappings_on_discarded_at ON public.lead_integration_macro_mappings USING btree (discarded_at);


--
-- TOC entry 6775 (class 1259 OID 97109)
-- Name: index_lead_integration_macros_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_macros_on_discarded_at ON public.lead_integration_macros USING btree (discarded_at);


--
-- TOC entry 6776 (class 1259 OID 97110)
-- Name: index_lead_integration_macros_on_lead_integration_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_macros_on_lead_integration_id ON public.lead_integration_macros USING btree (lead_integration_id);


--
-- TOC entry 6777 (class 1259 OID 97111)
-- Name: index_lead_integration_macros_on_parent_macro_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_macros_on_parent_macro_id ON public.lead_integration_macros USING btree (parent_macro_id);


--
-- TOC entry 6778 (class 1259 OID 97112)
-- Name: index_lead_integration_macros_on_sf_lead_integration_macro_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_macros_on_sf_lead_integration_macro_id ON public.lead_integration_macros USING btree (sf_lead_integration_macro_id);


--
-- TOC entry 6781 (class 1259 OID 97113)
-- Name: index_lead_integration_req_headers_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_req_headers_on_discarded_at ON public.lead_integration_req_headers USING btree (discarded_at);


--
-- TOC entry 6782 (class 1259 OID 97114)
-- Name: index_lead_integration_req_headers_on_lead_integration_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_req_headers_on_lead_integration_id ON public.lead_integration_req_headers USING btree (lead_integration_id);


--
-- TOC entry 6785 (class 1259 OID 97115)
-- Name: index_lead_integration_req_logs_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_req_logs_on_created_at ON public.lead_integration_req_logs USING btree (created_at);


--
-- TOC entry 6786 (class 1259 OID 97116)
-- Name: index_lead_integration_req_logs_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_req_logs_on_discarded_at ON public.lead_integration_req_logs USING btree (discarded_at);


--
-- TOC entry 6787 (class 1259 OID 97117)
-- Name: index_lead_integration_req_logs_on_lead_integration_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_req_logs_on_lead_integration_id ON public.lead_integration_req_logs USING btree (lead_integration_id);


--
-- TOC entry 6790 (class 1259 OID 97118)
-- Name: index_lead_integration_req_payloads_on_lead_integration_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_req_payloads_on_lead_integration_id ON public.lead_integration_req_payloads USING btree (lead_integration_id);


--
-- TOC entry 6791 (class 1259 OID 97119)
-- Name: index_lead_integration_req_payloads_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integration_req_payloads_on_lead_type_id ON public.lead_integration_req_payloads USING btree (lead_type_id);


--
-- TOC entry 6794 (class 1259 OID 97120)
-- Name: index_lead_integrations_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integrations_on_account_id ON public.lead_integrations USING btree (account_id);


--
-- TOC entry 6795 (class 1259 OID 97121)
-- Name: index_lead_integrations_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integrations_on_discarded_at ON public.lead_integrations USING btree (discarded_at);


--
-- TOC entry 6796 (class 1259 OID 97122)
-- Name: index_lead_integrations_on_product_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_integrations_on_product_type_id ON public.lead_integrations USING btree (product_type_id);


--
-- TOC entry 6799 (class 1259 OID 97123)
-- Name: index_lead_listings_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_listings_on_account_id ON public.lead_listings USING btree (account_id);


--
-- TOC entry 6800 (class 1259 OID 97124)
-- Name: index_lead_listings_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_listings_on_ad_group_id ON public.lead_listings USING btree (ad_group_id);


--
-- TOC entry 6801 (class 1259 OID 97125)
-- Name: index_lead_listings_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_listings_on_brand_id ON public.lead_listings USING btree (brand_id);


--
-- TOC entry 6802 (class 1259 OID 97126)
-- Name: index_lead_listings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_listings_on_campaign_id ON public.lead_listings USING btree (campaign_id);


--
-- TOC entry 6803 (class 1259 OID 97127)
-- Name: index_lead_listings_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_listings_on_created_at ON public.lead_listings USING btree (created_at);


--
-- TOC entry 6804 (class 1259 OID 97128)
-- Name: index_lead_listings_on_lead_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_listings_on_lead_ping_id ON public.lead_listings USING btree (lead_ping_id);


--
-- TOC entry 6807 (class 1259 OID 97129)
-- Name: index_lead_opportunities_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_opportunities_on_account_id ON public.lead_opportunities USING btree (account_id);


--
-- TOC entry 6808 (class 1259 OID 97130)
-- Name: index_lead_opportunities_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_opportunities_on_ad_group_id ON public.lead_opportunities USING btree (ad_group_id);


--
-- TOC entry 6809 (class 1259 OID 97131)
-- Name: index_lead_opportunities_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_opportunities_on_brand_id ON public.lead_opportunities USING btree (brand_id);


--
-- TOC entry 6810 (class 1259 OID 97132)
-- Name: index_lead_opportunities_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_opportunities_on_campaign_id ON public.lead_opportunities USING btree (campaign_id);


--
-- TOC entry 6811 (class 1259 OID 97133)
-- Name: index_lead_opportunities_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_opportunities_on_created_at ON public.lead_opportunities USING btree (created_at);


--
-- TOC entry 6812 (class 1259 OID 97134)
-- Name: index_lead_opportunities_on_lead_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_opportunities_on_lead_ping_id ON public.lead_opportunities USING btree (lead_ping_id);


--
-- TOC entry 6815 (class 1259 OID 97135)
-- Name: index_lead_ping_debug_logs_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_debug_logs_on_created_at ON public.lead_ping_debug_logs USING btree (created_at);


--
-- TOC entry 6816 (class 1259 OID 97136)
-- Name: index_lead_ping_debug_logs_on_lead_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_debug_logs_on_lead_ping_id ON public.lead_ping_debug_logs USING btree (lead_ping_id);


--
-- TOC entry 6819 (class 1259 OID 97137)
-- Name: index_lead_ping_details_on_lead_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_details_on_lead_ping_id ON public.lead_ping_details USING btree (lead_ping_id);


--
-- TOC entry 6822 (class 1259 OID 97138)
-- Name: index_lead_ping_matches_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_matches_on_account_id ON public.lead_ping_matches USING btree (account_id);


--
-- TOC entry 6823 (class 1259 OID 97139)
-- Name: index_lead_ping_matches_on_ad_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_matches_on_ad_group_id ON public.lead_ping_matches USING btree (ad_group_id);


--
-- TOC entry 6824 (class 1259 OID 97140)
-- Name: index_lead_ping_matches_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_matches_on_brand_id ON public.lead_ping_matches USING btree (brand_id);


--
-- TOC entry 6825 (class 1259 OID 97141)
-- Name: index_lead_ping_matches_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_matches_on_campaign_id ON public.lead_ping_matches USING btree (campaign_id);


--
-- TOC entry 6826 (class 1259 OID 97142)
-- Name: index_lead_ping_matches_on_lead_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_ping_matches_on_lead_ping_id ON public.lead_ping_matches USING btree (lead_ping_id);


--
-- TOC entry 6829 (class 1259 OID 97143)
-- Name: index_lead_pings_on_aid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_pings_on_aid ON public.lead_pings USING btree (aid);


--
-- TOC entry 6830 (class 1259 OID 97144)
-- Name: index_lead_pings_on_cid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_pings_on_cid ON public.lead_pings USING btree (cid);


--
-- TOC entry 6831 (class 1259 OID 97145)
-- Name: index_lead_pings_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_pings_on_created_at ON public.lead_pings USING btree (created_at);


--
-- TOC entry 6832 (class 1259 OID 97146)
-- Name: index_lead_pings_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_pings_on_lead_type_id ON public.lead_pings USING btree (lead_type_id);


--
-- TOC entry 6833 (class 1259 OID 97147)
-- Name: index_lead_pings_on_partner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_pings_on_partner_id ON public.lead_pings USING btree (partner_id);


--
-- TOC entry 6834 (class 1259 OID 97148)
-- Name: index_lead_pings_on_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_pings_on_uid ON public.lead_pings USING btree (uid);


--
-- TOC entry 6837 (class 1259 OID 97149)
-- Name: index_lead_post_details_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_post_details_on_email ON public.lead_post_details USING btree (email);


--
-- TOC entry 6838 (class 1259 OID 97150)
-- Name: index_lead_post_details_on_lead_post_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_post_details_on_lead_post_id ON public.lead_post_details USING btree (lead_post_id);


--
-- TOC entry 6841 (class 1259 OID 97151)
-- Name: index_lead_post_legs_on_bid_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_post_legs_on_bid_id ON public.lead_post_legs USING btree (bid_id);


--
-- TOC entry 6842 (class 1259 OID 97152)
-- Name: index_lead_post_legs_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_post_legs_on_created_at ON public.lead_post_legs USING btree (created_at);


--
-- TOC entry 6843 (class 1259 OID 97153)
-- Name: index_lead_post_legs_on_lead_post_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_post_legs_on_lead_post_id ON public.lead_post_legs USING btree (lead_post_id);


--
-- TOC entry 6846 (class 1259 OID 97154)
-- Name: index_lead_posts_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_posts_on_created_at ON public.lead_posts USING btree (created_at);


--
-- TOC entry 6847 (class 1259 OID 97155)
-- Name: index_lead_posts_on_lead_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_posts_on_lead_ping_id ON public.lead_posts USING btree (lead_ping_id);


--
-- TOC entry 6848 (class 1259 OID 97156)
-- Name: index_lead_posts_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_posts_on_lead_type_id ON public.lead_posts USING btree (lead_type_id);


--
-- TOC entry 6849 (class 1259 OID 97157)
-- Name: index_lead_posts_on_partner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_posts_on_partner_id ON public.lead_posts USING btree (partner_id);


--
-- TOC entry 6852 (class 1259 OID 97158)
-- Name: index_lead_prices_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_prices_on_lead_type_id ON public.lead_prices USING btree (lead_type_id);


--
-- TOC entry 6853 (class 1259 OID 97159)
-- Name: index_lead_prices_on_shared_and_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_lead_prices_on_shared_and_lead_type_id ON public.lead_prices USING btree (shared, lead_type_id);


--
-- TOC entry 6856 (class 1259 OID 97160)
-- Name: index_lead_refund_reasons_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_refund_reasons_on_discarded_at ON public.lead_refund_reasons USING btree (discarded_at);


--
-- TOC entry 6859 (class 1259 OID 97161)
-- Name: index_lead_refunds_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_refunds_on_discarded_at ON public.lead_refunds USING btree (discarded_at);


--
-- TOC entry 6860 (class 1259 OID 97162)
-- Name: index_lead_refunds_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_refunds_on_user_id ON public.lead_refunds USING btree (user_id);


--
-- TOC entry 6865 (class 1259 OID 97163)
-- Name: index_lead_vehicles_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_vehicles_on_discarded_at ON public.lead_vehicles USING btree (discarded_at);


--
-- TOC entry 6866 (class 1259 OID 97164)
-- Name: index_lead_vehicles_on_lead_applicant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_vehicles_on_lead_applicant_id ON public.lead_vehicles USING btree (lead_applicant_id);


--
-- TOC entry 6867 (class 1259 OID 97165)
-- Name: index_lead_vehicles_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_vehicles_on_lead_id ON public.lead_vehicles USING btree (lead_id);


--
-- TOC entry 6870 (class 1259 OID 97166)
-- Name: index_lead_violations_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_violations_on_discarded_at ON public.lead_violations USING btree (discarded_at);


--
-- TOC entry 6871 (class 1259 OID 97167)
-- Name: index_lead_violations_on_dt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_violations_on_dt ON public.lead_violations USING btree (dt);


--
-- TOC entry 6872 (class 1259 OID 97168)
-- Name: index_lead_violations_on_lead_applicant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_violations_on_lead_applicant_id ON public.lead_violations USING btree (lead_applicant_id);


--
-- TOC entry 6873 (class 1259 OID 97169)
-- Name: index_lead_violations_on_lead_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_violations_on_lead_id ON public.lead_violations USING btree (lead_id);


--
-- TOC entry 6874 (class 1259 OID 97170)
-- Name: index_lead_violations_on_violation_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_lead_violations_on_violation_type_id ON public.lead_violations USING btree (violation_type_id);


--
-- TOC entry 6884 (class 1259 OID 97171)
-- Name: index_leads_customize_columns_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_leads_customize_columns_orders_on_user_id ON public.leads_customize_columns_orders USING btree (user_id);


--
-- TOC entry 6887 (class 1259 OID 97172)
-- Name: index_leads_dashboard_customize_column_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_leads_dashboard_customize_column_orders_on_user_id ON public.leads_dashboard_customize_column_orders USING btree (user_id);


--
-- TOC entry 6877 (class 1259 OID 97173)
-- Name: index_leads_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_leads_on_account_id ON public.leads USING btree (account_id);


--
-- TOC entry 6878 (class 1259 OID 97174)
-- Name: index_leads_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_leads_on_campaign_id ON public.leads USING btree (campaign_id);


--
-- TOC entry 6879 (class 1259 OID 97175)
-- Name: index_leads_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_leads_on_created_at ON public.leads USING btree (created_at);


--
-- TOC entry 6880 (class 1259 OID 97176)
-- Name: index_leads_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_leads_on_lead_type_id ON public.leads USING btree (lead_type_id);


--
-- TOC entry 6881 (class 1259 OID 97177)
-- Name: index_leads_on_product_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_leads_on_product_type_id ON public.leads USING btree (product_type_id);


--
-- TOC entry 6890 (class 1259 OID 97178)
-- Name: index_memberships_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_memberships_on_account_id ON public.memberships USING btree (account_id);


--
-- TOC entry 6891 (class 1259 OID 97179)
-- Name: index_memberships_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_memberships_on_discarded_at ON public.memberships USING btree (discarded_at);


--
-- TOC entry 6892 (class 1259 OID 97180)
-- Name: index_memberships_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_memberships_on_user_id ON public.memberships USING btree (user_id);


--
-- TOC entry 6895 (class 1259 OID 97181)
-- Name: index_mv_refresh_statuses_on_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_mv_refresh_statuses_on_name ON public.mv_refresh_statuses USING btree (name);


--
-- TOC entry 6896 (class 1259 OID 97182)
-- Name: index_mv_refresh_statuses_on_start_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_mv_refresh_statuses_on_start_time ON public.mv_refresh_statuses USING btree (start_time);


--
-- TOC entry 6897 (class 1259 OID 97183)
-- Name: index_mv_refresh_statuses_on_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_mv_refresh_statuses_on_status ON public.mv_refresh_statuses USING btree (status);


--
-- TOC entry 6900 (class 1259 OID 97184)
-- Name: index_non_rtb_ping_stats_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_non_rtb_ping_stats_on_account_id ON public.non_rtb_ping_stats USING btree (account_id);


--
-- TOC entry 6901 (class 1259 OID 97185)
-- Name: index_non_rtb_ping_stats_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_non_rtb_ping_stats_on_campaign_id ON public.non_rtb_ping_stats USING btree (campaign_id);


--
-- TOC entry 6902 (class 1259 OID 97186)
-- Name: index_non_rtb_ping_stats_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_non_rtb_ping_stats_on_email ON public.non_rtb_ping_stats USING btree (email);


--
-- TOC entry 6903 (class 1259 OID 97187)
-- Name: index_non_rtb_ping_stats_on_listing_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_non_rtb_ping_stats_on_listing_id ON public.non_rtb_ping_stats USING btree (listing_id);


--
-- TOC entry 6904 (class 1259 OID 97188)
-- Name: index_non_rtb_ping_stats_on_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_non_rtb_ping_stats_on_phone ON public.non_rtb_ping_stats USING btree (phone);


--
-- TOC entry 6905 (class 1259 OID 97189)
-- Name: index_non_rtb_ping_stats_on_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_non_rtb_ping_stats_on_ping_id ON public.non_rtb_ping_stats USING btree (ping_id);


--
-- TOC entry 6908 (class 1259 OID 97190)
-- Name: index_notification_events_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_notification_events_on_account_id ON public.notification_events USING btree (account_id);


--
-- TOC entry 6909 (class 1259 OID 97191)
-- Name: index_notification_events_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_notification_events_on_brand_id ON public.notification_events USING btree (brand_id);


--
-- TOC entry 6910 (class 1259 OID 97192)
-- Name: index_notification_events_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_notification_events_on_created_at ON public.notification_events USING btree (created_at);


--
-- TOC entry 6913 (class 1259 OID 97193)
-- Name: index_notification_job_sources_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_notification_job_sources_on_account_id ON public.notification_job_sources USING btree (account_id);


--
-- TOC entry 6916 (class 1259 OID 97194)
-- Name: index_notification_preferences_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_notification_preferences_on_account_id ON public.notification_preferences USING btree (account_id);


--
-- TOC entry 6917 (class 1259 OID 97195)
-- Name: index_notification_preferences_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_notification_preferences_on_brand_id ON public.notification_preferences USING btree (brand_id);


--
-- TOC entry 6923 (class 1259 OID 97196)
-- Name: index_page_groups_on_quote_funnel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_page_groups_on_quote_funnel_id ON public.page_groups USING btree (quote_funnel_id);


--
-- TOC entry 6926 (class 1259 OID 97197)
-- Name: index_pages_on_page_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_pages_on_page_group_id ON public.pages USING btree (page_group_id);


--
-- TOC entry 6927 (class 1259 OID 97198)
-- Name: index_pages_on_quote_funnel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_pages_on_quote_funnel_id ON public.pages USING btree (quote_funnel_id);


--
-- TOC entry 6920 (class 1259 OID 97199)
-- Name: index_password_archivable; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_password_archivable ON public.old_passwords USING btree (password_archivable_type, password_archivable_id);


--
-- TOC entry 6932 (class 1259 OID 97200)
-- Name: index_permissions_on_feature_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_permissions_on_feature_id ON public.permissions USING btree (feature_id);


--
-- TOC entry 6933 (class 1259 OID 97201)
-- Name: index_permissions_on_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_permissions_on_role_id ON public.permissions USING btree (role_id);


--
-- TOC entry 6938 (class 1259 OID 97202)
-- Name: index_popup_lead_type_messages_on_agent_profile_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_popup_lead_type_messages_on_agent_profile_id ON public.popup_lead_type_messages USING btree (agent_profile_id);


--
-- TOC entry 6939 (class 1259 OID 97203)
-- Name: index_popup_lead_type_messages_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_popup_lead_type_messages_on_lead_type_id ON public.popup_lead_type_messages USING btree (lead_type_id);


--
-- TOC entry 6942 (class 1259 OID 97204)
-- Name: index_postback_url_req_logs_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_postback_url_req_logs_on_account_id ON public.postback_url_req_logs USING btree (account_id);


--
-- TOC entry 6943 (class 1259 OID 97205)
-- Name: index_postback_url_req_logs_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_postback_url_req_logs_on_campaign_id ON public.postback_url_req_logs USING btree (campaign_id);


--
-- TOC entry 6944 (class 1259 OID 97206)
-- Name: index_postback_url_req_logs_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_postback_url_req_logs_on_discarded_at ON public.postback_url_req_logs USING btree (discarded_at);


--
-- TOC entry 6947 (class 1259 OID 97207)
-- Name: index_pp_ping_report_accounts_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_pp_ping_report_accounts_on_account_id ON public.pp_ping_report_accounts USING btree (account_id);


--
-- TOC entry 6950 (class 1259 OID 97208)
-- Name: index_prefill_queries_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_prefill_queries_on_brand_id ON public.prefill_queries USING btree (brand_id);


--
-- TOC entry 6951 (class 1259 OID 97209)
-- Name: index_prefill_queries_on_click_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_prefill_queries_on_click_id ON public.prefill_queries USING btree (click_id);


--
-- TOC entry 6952 (class 1259 OID 97210)
-- Name: index_prefill_queries_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_prefill_queries_on_created_at ON public.prefill_queries USING btree (created_at);


--
-- TOC entry 6953 (class 1259 OID 97211)
-- Name: index_prefill_queries_on_phone_num; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_prefill_queries_on_phone_num ON public.prefill_queries USING btree (phone_num);


--
-- TOC entry 6954 (class 1259 OID 97212)
-- Name: index_prefill_queries_on_quote_funnel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_prefill_queries_on_quote_funnel_id ON public.prefill_queries USING btree (quote_funnel_id);


--
-- TOC entry 6955 (class 1259 OID 97213)
-- Name: index_prefill_queries_on_session_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_prefill_queries_on_session_id ON public.prefill_queries USING btree (session_id);


--
-- TOC entry 6960 (class 1259 OID 97214)
-- Name: index_prospects_customize_columns_orders_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_prospects_customize_columns_orders_on_user_id ON public.prospects_customize_columns_orders USING btree (user_id);


--
-- TOC entry 6963 (class 1259 OID 97215)
-- Name: index_qf_call_integrations_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_call_integrations_on_campaign_id ON public.qf_call_integrations USING btree (campaign_id);


--
-- TOC entry 6964 (class 1259 OID 97216)
-- Name: index_qf_call_integrations_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_call_integrations_on_discarded_at ON public.qf_call_integrations USING btree (discarded_at);


--
-- TOC entry 6967 (class 1259 OID 97217)
-- Name: index_qf_call_settings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_call_settings_on_campaign_id ON public.qf_call_settings USING btree (campaign_id);


--
-- TOC entry 6968 (class 1259 OID 97218)
-- Name: index_qf_call_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_call_settings_on_discarded_at ON public.qf_call_settings USING btree (discarded_at);


--
-- TOC entry 6971 (class 1259 OID 97219)
-- Name: index_qf_lead_integrations_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_lead_integrations_on_campaign_id ON public.qf_lead_integrations USING btree (campaign_id);


--
-- TOC entry 6972 (class 1259 OID 97220)
-- Name: index_qf_lead_integrations_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_lead_integrations_on_discarded_at ON public.qf_lead_integrations USING btree (discarded_at);


--
-- TOC entry 6975 (class 1259 OID 97221)
-- Name: index_qf_lead_settings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_lead_settings_on_campaign_id ON public.qf_lead_settings USING btree (campaign_id);


--
-- TOC entry 6976 (class 1259 OID 97222)
-- Name: index_qf_lead_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_lead_settings_on_discarded_at ON public.qf_lead_settings USING btree (discarded_at);


--
-- TOC entry 6979 (class 1259 OID 97223)
-- Name: index_qf_quote_call_qas_on_qf_quote_call_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_call_qas_on_qf_quote_call_id ON public.qf_quote_call_qas USING btree (qf_quote_call_id);


--
-- TOC entry 6982 (class 1259 OID 97224)
-- Name: index_qf_quote_call_summaries_on_qf_quote_call_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_call_summaries_on_qf_quote_call_id ON public.qf_quote_call_summaries USING btree (qf_quote_call_id);


--
-- TOC entry 6985 (class 1259 OID 97225)
-- Name: index_qf_quote_call_transcriptions_on_qf_quote_call_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_call_transcriptions_on_qf_quote_call_id ON public.qf_quote_call_transcriptions USING btree (qf_quote_call_id);


--
-- TOC entry 6989 (class 1259 OID 97226)
-- Name: index_qf_quote_calls_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_calls_on_account_id ON public.qf_quote_calls USING btree (account_id);


--
-- TOC entry 6990 (class 1259 OID 97227)
-- Name: index_qf_quote_calls_on_call_sid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_calls_on_call_sid ON public.qf_quote_calls USING btree (call_sid);


--
-- TOC entry 6991 (class 1259 OID 97228)
-- Name: index_qf_quote_calls_on_caller; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_calls_on_caller ON public.qf_quote_calls USING btree (caller);


--
-- TOC entry 6992 (class 1259 OID 97229)
-- Name: index_qf_quote_calls_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_calls_on_campaign_id ON public.qf_quote_calls USING btree (campaign_id);


--
-- TOC entry 6993 (class 1259 OID 97230)
-- Name: index_qf_quote_calls_on_campaign_id_and_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_calls_on_campaign_id_and_status ON public.qf_quote_calls USING btree (campaign_id, status);


--
-- TOC entry 6994 (class 1259 OID 97231)
-- Name: index_qf_quote_calls_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_qf_quote_calls_on_created_at ON public.qf_quote_calls USING btree (created_at);


--
-- TOC entry 6997 (class 1259 OID 97232)
-- Name: index_question_groups_on_page_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_question_groups_on_page_group_id ON public.question_groups USING btree (page_group_id);


--
-- TOC entry 6998 (class 1259 OID 97233)
-- Name: index_question_groups_on_page_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_question_groups_on_page_id ON public.question_groups USING btree (page_id);


--
-- TOC entry 6999 (class 1259 OID 97234)
-- Name: index_question_groups_on_quote_funnel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_question_groups_on_quote_funnel_id ON public.question_groups USING btree (quote_funnel_id);


--
-- TOC entry 7002 (class 1259 OID 97235)
-- Name: index_questions_on_page_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_questions_on_page_group_id ON public.questions USING btree (page_group_id);


--
-- TOC entry 7003 (class 1259 OID 97236)
-- Name: index_questions_on_page_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_questions_on_page_id ON public.questions USING btree (page_id);


--
-- TOC entry 7004 (class 1259 OID 97237)
-- Name: index_questions_on_question_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_questions_on_question_group_id ON public.questions USING btree (question_group_id);


--
-- TOC entry 7005 (class 1259 OID 97238)
-- Name: index_questions_on_quote_funnel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_questions_on_quote_funnel_id ON public.questions USING btree (quote_funnel_id);


--
-- TOC entry 7008 (class 1259 OID 97239)
-- Name: index_quote_call_qas_on_quote_call_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_call_qas_on_quote_call_id ON public.quote_call_qas USING btree (quote_call_id);


--
-- TOC entry 7011 (class 1259 OID 97240)
-- Name: index_quote_call_summaries_on_quote_call_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_call_summaries_on_quote_call_id ON public.quote_call_summaries USING btree (quote_call_id);


--
-- TOC entry 7014 (class 1259 OID 97241)
-- Name: index_quote_call_transcriptions_on_quote_call_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_call_transcriptions_on_quote_call_id ON public.quote_call_transcriptions USING btree (quote_call_id);


--
-- TOC entry 7018 (class 1259 OID 97242)
-- Name: index_quote_calls_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_calls_on_account_id ON public.quote_calls USING btree (account_id);


--
-- TOC entry 7019 (class 1259 OID 97243)
-- Name: index_quote_calls_on_call_sid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_calls_on_call_sid ON public.quote_calls USING btree (call_sid);


--
-- TOC entry 7020 (class 1259 OID 97244)
-- Name: index_quote_calls_on_caller; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_calls_on_caller ON public.quote_calls USING btree (caller);


--
-- TOC entry 7021 (class 1259 OID 97245)
-- Name: index_quote_calls_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_calls_on_campaign_id ON public.quote_calls USING btree (campaign_id);


--
-- TOC entry 7022 (class 1259 OID 97246)
-- Name: index_quote_calls_on_campaign_id_and_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_calls_on_campaign_id_and_status ON public.quote_calls USING btree (campaign_id, status);


--
-- TOC entry 7023 (class 1259 OID 97247)
-- Name: index_quote_calls_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_calls_on_created_at ON public.quote_calls USING btree (created_at);


--
-- TOC entry 7024 (class 1259 OID 97248)
-- Name: index_quote_calls_on_created_at_and_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_calls_on_created_at_and_account_id ON public.quote_calls USING btree (created_at, account_id);


--
-- TOC entry 7027 (class 1259 OID 97249)
-- Name: index_quote_form_visits_on_ip_and_user_agent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_form_visits_on_ip_and_user_agent ON public.quote_form_visits USING btree (ip, user_agent);


--
-- TOC entry 7028 (class 1259 OID 97250)
-- Name: index_quote_form_visits_on_prefill_query_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_form_visits_on_prefill_query_id ON public.quote_form_visits USING btree (prefill_query_id);


--
-- TOC entry 7031 (class 1259 OID 97251)
-- Name: index_quote_funnels_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_funnels_on_account_id ON public.quote_funnels USING btree (account_id);


--
-- TOC entry 7032 (class 1259 OID 97252)
-- Name: index_quote_funnels_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_funnels_on_lead_type_id ON public.quote_funnels USING btree (lead_type_id);


--
-- TOC entry 7035 (class 1259 OID 97253)
-- Name: index_quote_funnels_prices_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_quote_funnels_prices_on_lead_type_id ON public.quote_funnels_prices USING btree (lead_type_id);


--
-- TOC entry 7038 (class 1259 OID 97254)
-- Name: index_rds_logs_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rds_logs_on_created_at ON public.rds_logs USING btree (created_at);


--
-- TOC entry 7039 (class 1259 OID 97255)
-- Name: index_rds_logs_on_duration_ms; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rds_logs_on_duration_ms ON public.rds_logs USING btree (duration_ms);


--
-- TOC entry 7040 (class 1259 OID 97256)
-- Name: index_rds_logs_on_log_stream; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rds_logs_on_log_stream ON public.rds_logs USING btree (log_stream);


--
-- TOC entry 7041 (class 1259 OID 97257)
-- Name: index_rds_logs_on_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rds_logs_on_timestamp ON public.rds_logs USING btree ("timestamp");


--
-- TOC entry 7048 (class 1259 OID 97258)
-- Name: index_receipts_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_account_id ON public.receipts USING btree (account_id);


--
-- TOC entry 7049 (class 1259 OID 97259)
-- Name: index_receipts_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_brand_id ON public.receipts USING btree (brand_id);


--
-- TOC entry 7050 (class 1259 OID 97260)
-- Name: index_receipts_on_brand_id_and_invoice_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_brand_id_and_invoice_id ON public.receipts USING btree (brand_id, invoice_id);


--
-- TOC entry 7051 (class 1259 OID 97261)
-- Name: index_receipts_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_campaign_id ON public.receipts USING btree (campaign_id);


--
-- TOC entry 7052 (class 1259 OID 97262)
-- Name: index_receipts_on_campaign_id_and_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_campaign_id_and_created_at ON public.receipts USING btree (campaign_id, created_at);


--
-- TOC entry 7053 (class 1259 OID 97263)
-- Name: index_receipts_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_created_at ON public.receipts USING btree (created_at);


--
-- TOC entry 7054 (class 1259 OID 97264)
-- Name: index_receipts_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_discarded_at ON public.receipts USING btree (discarded_at);


--
-- TOC entry 7055 (class 1259 OID 97265)
-- Name: index_receipts_on_receipt_transaction_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_receipt_transaction_type_id ON public.receipts USING btree (receipt_transaction_type_id);


--
-- TOC entry 7056 (class 1259 OID 97266)
-- Name: index_receipts_on_receipt_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_receipt_type_id ON public.receipts USING btree (receipt_type_id);


--
-- TOC entry 7057 (class 1259 OID 97267)
-- Name: index_receipts_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_receipts_on_user_id ON public.receipts USING btree (user_id);


--
-- TOC entry 7060 (class 1259 OID 97268)
-- Name: index_recently_visited_client_users_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_recently_visited_client_users_on_account_id ON public.recently_visited_client_users USING btree (account_id);


--
-- TOC entry 7061 (class 1259 OID 97269)
-- Name: index_recently_visited_client_users_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_recently_visited_client_users_on_admin_user_id ON public.recently_visited_client_users USING btree (admin_user_id);


--
-- TOC entry 7064 (class 1259 OID 97270)
-- Name: index_registration_pending_users_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_registration_pending_users_on_discarded_at ON public.registration_pending_users USING btree (discarded_at);


--
-- TOC entry 7065 (class 1259 OID 97271)
-- Name: index_registration_pending_users_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_registration_pending_users_on_email ON public.registration_pending_users USING btree (email);


--
-- TOC entry 7066 (class 1259 OID 97272)
-- Name: index_registration_pending_users_on_sales_manager_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_registration_pending_users_on_sales_manager_id ON public.registration_pending_users USING btree (sales_manager_id);


--
-- TOC entry 7067 (class 1259 OID 97273)
-- Name: index_registration_pending_users_on_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_registration_pending_users_on_uuid ON public.registration_pending_users USING btree (uuid);


--
-- TOC entry 7072 (class 1259 OID 97274)
-- Name: index_roles_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_roles_on_account_id ON public.roles USING btree (account_id);


--
-- TOC entry 7073 (class 1259 OID 97275)
-- Name: index_roles_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_roles_on_discarded_at ON public.roles USING btree (discarded_at);


--
-- TOC entry 7074 (class 1259 OID 97276)
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- TOC entry 7077 (class 1259 OID 97277)
-- Name: index_rtb_bids_on_click_ping_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rtb_bids_on_click_ping_id ON public.rtb_bids USING btree (click_ping_id);


--
-- TOC entry 7080 (class 1259 OID 97278)
-- Name: index_rule_validator_checks_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rule_validator_checks_on_account_id ON public.rule_validator_checks USING btree (account_id);


--
-- TOC entry 7081 (class 1259 OID 97279)
-- Name: index_rule_validator_checks_on_product_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rule_validator_checks_on_product_name ON public.rule_validator_checks USING btree (product_name);


--
-- TOC entry 7082 (class 1259 OID 97280)
-- Name: index_rule_validator_checks_on_rule_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rule_validator_checks_on_rule_name ON public.rule_validator_checks USING btree (rule_name);


--
-- TOC entry 7083 (class 1259 OID 97281)
-- Name: index_rule_validator_checks_on_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rule_validator_checks_on_status ON public.rule_validator_checks USING btree (status);


--
-- TOC entry 7084 (class 1259 OID 97282)
-- Name: index_rule_validator_checks_on_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rule_validator_checks_on_timestamp ON public.rule_validator_checks USING btree ("timestamp");


--
-- TOC entry 7087 (class 1259 OID 97283)
-- Name: index_sample_leads_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sample_leads_on_lead_type_id ON public.sample_leads USING btree (lead_type_id);


--
-- TOC entry 7090 (class 1259 OID 97284)
-- Name: index_scheduled_report_emails_on_scheduled_report_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_report_emails_on_scheduled_report_id ON public.scheduled_report_emails USING btree (scheduled_report_id);


--
-- TOC entry 7093 (class 1259 OID 97285)
-- Name: index_scheduled_report_logs_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_report_logs_on_account_id ON public.scheduled_report_logs USING btree (account_id);


--
-- TOC entry 7094 (class 1259 OID 97286)
-- Name: index_scheduled_report_logs_on_scheduled_report_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_report_logs_on_scheduled_report_id ON public.scheduled_report_logs USING btree (scheduled_report_id);


--
-- TOC entry 7095 (class 1259 OID 97287)
-- Name: index_scheduled_report_logs_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_report_logs_on_user_id ON public.scheduled_report_logs USING btree (user_id);


--
-- TOC entry 7098 (class 1259 OID 97288)
-- Name: index_scheduled_report_sftps_on_scheduled_report_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_report_sftps_on_scheduled_report_id ON public.scheduled_report_sftps USING btree (scheduled_report_id);


--
-- TOC entry 7101 (class 1259 OID 97289)
-- Name: index_scheduled_report_uploads_on_scheduled_report_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_report_uploads_on_scheduled_report_id ON public.scheduled_report_uploads USING btree (scheduled_report_id);


--
-- TOC entry 7102 (class 1259 OID 97290)
-- Name: index_scheduled_report_uploads_on_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_report_uploads_on_token ON public.scheduled_report_uploads USING btree (token);


--
-- TOC entry 7105 (class 1259 OID 97291)
-- Name: index_scheduled_reports_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_reports_on_account_id ON public.scheduled_reports USING btree (account_id);


--
-- TOC entry 7106 (class 1259 OID 97292)
-- Name: index_scheduled_reports_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_reports_on_discarded_at ON public.scheduled_reports USING btree (discarded_at);


--
-- TOC entry 7107 (class 1259 OID 97293)
-- Name: index_scheduled_reports_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_reports_on_updated_at ON public.scheduled_reports USING btree (updated_at);


--
-- TOC entry 7108 (class 1259 OID 97294)
-- Name: index_scheduled_reports_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_reports_on_user_id ON public.scheduled_reports USING btree (user_id);


--
-- TOC entry 7109 (class 1259 OID 97295)
-- Name: index_scheduled_reports_on_user_smart_view_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_scheduled_reports_on_user_smart_view_id ON public.scheduled_reports USING btree (user_smart_view_id);


--
-- TOC entry 7114 (class 1259 OID 97296)
-- Name: index_semaphore_deployments_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_semaphore_deployments_on_created_at ON public.semaphore_deployments USING btree (created_at);


--
-- TOC entry 7117 (class 1259 OID 97297)
-- Name: index_sf_filters_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sf_filters_on_discarded_at ON public.sf_filters USING btree (discarded_at);


--
-- TOC entry 7118 (class 1259 OID 97298)
-- Name: index_sf_filters_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sf_filters_on_lead_type_id ON public.sf_filters USING btree (lead_type_id);


--
-- TOC entry 7119 (class 1259 OID 97299)
-- Name: index_sf_filters_on_product_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sf_filters_on_product_type_id ON public.sf_filters USING btree (product_type_id);


--
-- TOC entry 7124 (class 1259 OID 97300)
-- Name: index_sf_lead_integration_macro_lead_types_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sf_lead_integration_macro_lead_types_on_lead_type_id ON public.sf_lead_integration_macro_lead_types USING btree (lead_type_id);


--
-- TOC entry 7128 (class 1259 OID 97301)
-- Name: index_sf_lead_integration_macros_on_parent_macro_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sf_lead_integration_macros_on_parent_macro_id ON public.sf_lead_integration_macros USING btree (parent_macro_id);


--
-- TOC entry 7125 (class 1259 OID 97302)
-- Name: index_sf_li_macro_lead_type_on_sf_li_macro; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sf_li_macro_lead_type_on_sf_li_macro ON public.sf_lead_integration_macro_lead_types USING btree (sf_lead_integration_macro_id);


--
-- TOC entry 7131 (class 1259 OID 97303)
-- Name: index_sf_smart_views_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sf_smart_views_on_discarded_at ON public.sf_smart_views USING btree (discarded_at);


--
-- TOC entry 7134 (class 1259 OID 97304)
-- Name: index_sidekiq_job_error_logs_on_job_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sidekiq_job_error_logs_on_job_name ON public.sidekiq_job_error_logs USING btree (job_name);


--
-- TOC entry 7135 (class 1259 OID 97305)
-- Name: index_sidekiq_job_error_logs_on_job_name_and_source_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_sidekiq_job_error_logs_on_job_name_and_source_id ON public.sidekiq_job_error_logs USING btree (job_name, source_id);


--
-- TOC entry 7140 (class 1259 OID 97306)
-- Name: index_slow_query_logs_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_slow_query_logs_on_created_at ON public.slow_query_logs USING btree (created_at);


--
-- TOC entry 7143 (class 1259 OID 97307)
-- Name: index_source_pixel_columns_on_click_conversion_pixel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_source_pixel_columns_on_click_conversion_pixel_id ON public.source_pixel_columns USING btree (click_conversion_pixel_id);


--
-- TOC entry 7146 (class 1259 OID 97308)
-- Name: index_source_setting_notes_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_source_setting_notes_on_admin_user_id ON public.source_setting_notes USING btree (admin_user_id);


--
-- TOC entry 7147 (class 1259 OID 97309)
-- Name: index_source_setting_notes_on_campaign_source_setting_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_source_setting_notes_on_campaign_source_setting_id ON public.source_setting_notes USING btree (campaign_source_setting_id);


--
-- TOC entry 7148 (class 1259 OID 97310)
-- Name: index_source_setting_notes_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_source_setting_notes_on_discarded_at ON public.source_setting_notes USING btree (discarded_at);


--
-- TOC entry 7151 (class 1259 OID 97311)
-- Name: index_source_types_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_source_types_on_discarded_at ON public.source_types USING btree (discarded_at);


--
-- TOC entry 7152 (class 1259 OID 97312)
-- Name: index_source_types_on_name_and_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_source_types_on_name_and_project_id ON public.source_types USING btree (name, project_id);


--
-- TOC entry 7155 (class 1259 OID 97313)
-- Name: index_state_names_on_state_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_state_names_on_state_code ON public.state_names USING btree (state_code);


--
-- TOC entry 7158 (class 1259 OID 97314)
-- Name: index_syndi_click_rules_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_syndi_click_rules_on_campaign_id ON public.syndi_click_rules USING btree (campaign_id);


--
-- TOC entry 7159 (class 1259 OID 97315)
-- Name: index_syndi_click_rules_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_syndi_click_rules_on_discarded_at ON public.syndi_click_rules USING btree (discarded_at);


--
-- TOC entry 7162 (class 1259 OID 97316)
-- Name: index_syndi_click_settings_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_syndi_click_settings_on_campaign_id ON public.syndi_click_settings USING btree (campaign_id);


--
-- TOC entry 7163 (class 1259 OID 97317)
-- Name: index_syndi_click_settings_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_syndi_click_settings_on_discarded_at ON public.syndi_click_settings USING btree (discarded_at);


--
-- TOC entry 7164 (class 1259 OID 97318)
-- Name: index_syndi_click_settings_on_lead_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_syndi_click_settings_on_lead_type_id ON public.syndi_click_settings USING btree (lead_type_id);


--
-- TOC entry 7167 (class 1259 OID 97319)
-- Name: index_template_assignments_on_admin_notification_template_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_template_assignments_on_admin_notification_template_id ON public.template_assignments USING btree (admin_notification_template_id);


--
-- TOC entry 7168 (class 1259 OID 97320)
-- Name: index_template_assignments_on_admin_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_template_assignments_on_admin_role_id ON public.template_assignments USING btree (admin_role_id);


--
-- TOC entry 7169 (class 1259 OID 97321)
-- Name: index_template_assignments_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_template_assignments_on_discarded_at ON public.template_assignments USING btree (discarded_at);


--
-- TOC entry 7176 (class 1259 OID 97322)
-- Name: index_twilio_phone_numbers_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_twilio_phone_numbers_on_account_id ON public.twilio_phone_numbers USING btree (account_id);


--
-- TOC entry 7177 (class 1259 OID 97323)
-- Name: index_twilio_phone_numbers_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_twilio_phone_numbers_on_campaign_id ON public.twilio_phone_numbers USING btree (campaign_id);


--
-- TOC entry 7178 (class 1259 OID 97324)
-- Name: index_twilio_phone_numbers_on_phone_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_twilio_phone_numbers_on_phone_number ON public.twilio_phone_numbers USING btree (phone_number);


--
-- TOC entry 7179 (class 1259 OID 97325)
-- Name: index_twilio_phone_numbers_on_sid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_twilio_phone_numbers_on_sid ON public.twilio_phone_numbers USING btree (sid);


--
-- TOC entry 7182 (class 1259 OID 97326)
-- Name: index_user_activity_customize_columns_orders_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_activity_customize_columns_orders_on_admin_user_id ON public.user_activity_customize_columns_orders USING btree (admin_user_id);


--
-- TOC entry 7185 (class 1259 OID 97327)
-- Name: index_user_col_pref_admin_dashboards_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_admin_dashboards_on_admin_user_id ON public.user_col_pref_admin_dashboards USING btree (admin_user_id);


--
-- TOC entry 7188 (class 1259 OID 97328)
-- Name: index_user_col_pref_analytics_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_analytics_on_user_id ON public.user_col_pref_analytics USING btree (user_id);


--
-- TOC entry 7191 (class 1259 OID 97329)
-- Name: index_user_col_pref_calls_dashboard_campaigns_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_calls_dashboard_campaigns_on_user_id ON public.user_col_pref_calls_dashboard_campaigns USING btree (user_id);


--
-- TOC entry 7194 (class 1259 OID 97330)
-- Name: index_user_col_pref_calls_dashboard_states_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_calls_dashboard_states_on_user_id ON public.user_col_pref_calls_dashboard_states USING btree (user_id);


--
-- TOC entry 7197 (class 1259 OID 97331)
-- Name: index_user_col_pref_clicks_dashboards_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_clicks_dashboards_on_user_id ON public.user_col_pref_clicks_dashboards USING btree (user_id);


--
-- TOC entry 7200 (class 1259 OID 97332)
-- Name: index_user_col_pref_conversion_logs_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_conversion_logs_on_user_id ON public.user_col_pref_conversion_logs USING btree (user_id);


--
-- TOC entry 7203 (class 1259 OID 97333)
-- Name: index_user_col_pref_leads_dashboards_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_leads_dashboards_on_user_id ON public.user_col_pref_leads_dashboards USING btree (user_id);


--
-- TOC entry 7206 (class 1259 OID 97334)
-- Name: index_user_col_pref_syndi_clicks_dashboards_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_col_pref_syndi_clicks_dashboards_on_user_id ON public.user_col_pref_syndi_clicks_dashboards USING btree (user_id);


--
-- TOC entry 7209 (class 1259 OID 97335)
-- Name: index_user_column_preference_ad_groups_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_ad_groups_on_user_id ON public.user_column_preference_ad_groups USING btree (user_id);


--
-- TOC entry 7212 (class 1259 OID 97336)
-- Name: index_user_column_preference_call_profiles_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_call_profiles_on_user_id ON public.user_column_preference_call_profiles USING btree (user_id);


--
-- TOC entry 7215 (class 1259 OID 97337)
-- Name: index_user_column_preference_call_source_settings_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_call_source_settings_on_user_id ON public.user_column_preference_call_source_settings USING btree (user_id);


--
-- TOC entry 7218 (class 1259 OID 97338)
-- Name: index_user_column_preference_calls_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_calls_on_user_id ON public.user_column_preference_calls USING btree (user_id);


--
-- TOC entry 7221 (class 1259 OID 97339)
-- Name: index_user_column_preference_campaigns_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_campaigns_on_user_id ON public.user_column_preference_campaigns USING btree (user_id);


--
-- TOC entry 7224 (class 1259 OID 97340)
-- Name: index_user_column_preference_lead_profiles_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_lead_profiles_on_user_id ON public.user_column_preference_lead_profiles USING btree (user_id);


--
-- TOC entry 7227 (class 1259 OID 97341)
-- Name: index_user_column_preference_lead_source_settings_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_lead_source_settings_on_user_id ON public.user_column_preference_lead_source_settings USING btree (user_id);


--
-- TOC entry 7230 (class 1259 OID 97342)
-- Name: index_user_column_preference_leads_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_leads_on_user_id ON public.user_column_preference_leads USING btree (user_id);


--
-- TOC entry 7233 (class 1259 OID 97343)
-- Name: index_user_column_preference_prospects_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_prospects_on_user_id ON public.user_column_preference_prospects USING btree (user_id);


--
-- TOC entry 7236 (class 1259 OID 97344)
-- Name: index_user_column_preference_source_settings_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_column_preference_source_settings_on_user_id ON public.user_column_preference_source_settings USING btree (user_id);


--
-- TOC entry 7239 (class 1259 OID 97345)
-- Name: index_user_notifications_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_notifications_on_discarded_at ON public.user_notifications USING btree (discarded_at);


--
-- TOC entry 7240 (class 1259 OID 97346)
-- Name: index_user_notifications_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_notifications_on_user_id ON public.user_notifications USING btree (user_id);


--
-- TOC entry 7243 (class 1259 OID 97347)
-- Name: index_user_smart_views_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_smart_views_on_discarded_at ON public.user_smart_views USING btree (discarded_at);


--
-- TOC entry 7244 (class 1259 OID 97348)
-- Name: index_user_smart_views_on_hide; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_smart_views_on_hide ON public.user_smart_views USING btree (hide);


--
-- TOC entry 7245 (class 1259 OID 97349)
-- Name: index_user_smart_views_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_smart_views_on_user_id ON public.user_smart_views USING btree (user_id);


--
-- TOC entry 7248 (class 1259 OID 97350)
-- Name: index_user_terms_of_services_on_doc_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_terms_of_services_on_doc_id ON public.user_terms_of_services USING btree (doc_id);


--
-- TOC entry 7249 (class 1259 OID 97351)
-- Name: index_user_terms_of_services_on_user_ip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_user_terms_of_services_on_user_ip ON public.user_terms_of_services USING btree (user_ip);


--
-- TOC entry 7252 (class 1259 OID 97352)
-- Name: index_users_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_users_on_discarded_at ON public.users USING btree (discarded_at);


--
-- TOC entry 7253 (class 1259 OID 97353)
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- TOC entry 7254 (class 1259 OID 97354)
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- TOC entry 7257 (class 1259 OID 97355)
-- Name: index_versions_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_account_id ON public.versions USING btree (account_id);


--
-- TOC entry 7258 (class 1259 OID 97356)
-- Name: index_versions_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_admin_user_id ON public.versions USING btree (admin_user_id);


--
-- TOC entry 7259 (class 1259 OID 97357)
-- Name: index_versions_on_brand_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_brand_id ON public.versions USING btree (brand_id);


--
-- TOC entry 7260 (class 1259 OID 97358)
-- Name: index_versions_on_campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_campaign_id ON public.versions USING btree (campaign_id);


--
-- TOC entry 7261 (class 1259 OID 97359)
-- Name: index_versions_on_fk_id_and_fk_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_fk_id_and_fk_type ON public.versions USING btree (fk_id, fk_type);


--
-- TOC entry 7262 (class 1259 OID 97360)
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- TOC entry 7263 (class 1259 OID 97361)
-- Name: index_versions_on_transaction_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_transaction_id ON public.versions USING btree (transaction_id);


--
-- TOC entry 7271 (class 1259 OID 97362)
-- Name: index_wb_ulm_on_brand; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_wb_ulm_on_brand ON public.whitelabeled_brands_user_login_mappings USING btree (white_listing_brand_id);


--
-- TOC entry 7268 (class 1259 OID 97363)
-- Name: index_white_listing_brands_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_white_listing_brands_on_discarded_at ON public.white_listing_brands USING btree (discarded_at);


--
-- TOC entry 7272 (class 1259 OID 97364)
-- Name: index_whitelabeled_brands_user_login_mappings_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_whitelabeled_brands_user_login_mappings_on_admin_user_id ON public.whitelabeled_brands_user_login_mappings USING btree (admin_user_id);


--
-- TOC entry 7275 (class 1259 OID 97365)
-- Name: index_whitelisting_brand_admin_assignments_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_whitelisting_brand_admin_assignments_on_admin_user_id ON public.whitelisting_brand_admin_assignments USING btree (admin_user_id);


--
-- TOC entry 7276 (class 1259 OID 97366)
-- Name: index_whitelisting_brand_admin_assignments_on_brands_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_whitelisting_brand_admin_assignments_on_brands_id ON public.whitelisting_brand_admin_assignments USING btree (white_listing_brand_id);


--
-- TOC entry 7277 (class 1259 OID 97367)
-- Name: index_whitelisting_brand_admin_assignments_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_whitelisting_brand_admin_assignments_on_discarded_at ON public.whitelisting_brand_admin_assignments USING btree (discarded_at);


--
-- TOC entry 7280 (class 1259 OID 97368)
-- Name: index_zip_tier_locations_on_zip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_zip_tier_locations_on_zip ON public.zip_tier_locations USING btree (zip);


--
-- TOC entry 7281 (class 1259 OID 97369)
-- Name: index_zip_tier_locations_on_zip_tier_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_zip_tier_locations_on_zip_tier_id ON public.zip_tier_locations USING btree (zip_tier_id);


--
-- TOC entry 7284 (class 1259 OID 97370)
-- Name: index_zip_tiers_on_account_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_zip_tiers_on_account_id ON public.zip_tiers USING btree (account_id);


--
-- TOC entry 7285 (class 1259 OID 97371)
-- Name: index_zip_tiers_on_discarded_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_zip_tiers_on_discarded_at ON public.zip_tiers USING btree (discarded_at);


--
-- TOC entry 7288 (class 1259 OID 97372)
-- Name: index_zipcodes_on_zipcode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_zipcodes_on_zipcode ON public.zipcodes USING btree (zipcode);


--
-- TOC entry 7015 (class 1259 OID 97373)
-- Name: qc_transcription_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX qc_transcription_status ON public.quote_call_transcriptions USING btree (status);


--
-- TOC entry 6988 (class 1259 OID 97374)
-- Name: qf_transcription_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX qf_transcription_status ON public.qf_quote_call_transcriptions USING btree (status);


--
-- TOC entry 7331 (class 2606 OID 97375)
-- Name: assignments fk_rails_0028583927; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_0028583927 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- TOC entry 7349 (class 2606 OID 97380)
-- Name: campaign_ads fk_rails_0040aa3f40; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_ads
    ADD CONSTRAINT fk_rails_0040aa3f40 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7358 (class 2606 OID 97385)
-- Name: campaign_filter_packages fk_rails_0109dbdf36; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filter_packages
    ADD CONSTRAINT fk_rails_0109dbdf36 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7308 (class 2606 OID 97390)
-- Name: admin_notification_template_types fk_rails_041f6d7901; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_template_types
    ADD CONSTRAINT fk_rails_041f6d7901 FOREIGN KEY (admin_notification_type_id) REFERENCES public.admin_notification_types(id);


--
-- TOC entry 7397 (class 2606 OID 97395)
-- Name: lead_details fk_rails_057cdaa590; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_details
    ADD CONSTRAINT fk_rails_057cdaa590 FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- TOC entry 7492 (class 2606 OID 97400)
-- Name: user_smart_views fk_rails_06248f5370; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_smart_views
    ADD CONSTRAINT fk_rails_06248f5370 FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- TOC entry 7435 (class 2606 OID 97405)
-- Name: question_groups fk_rails_066c736b78; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.question_groups
    ADD CONSTRAINT fk_rails_066c736b78 FOREIGN KEY (quote_funnel_id) REFERENCES public.quote_funnels(id);


--
-- TOC entry 7376 (class 2606 OID 97410)
-- Name: campaigns fk_rails_06c0f322c9; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT fk_rails_06c0f322c9 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7354 (class 2606 OID 97415)
-- Name: campaign_budgets fk_rails_09bb5e1043; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_budgets
    ADD CONSTRAINT fk_rails_09bb5e1043 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7325 (class 2606 OID 97420)
-- Name: analytics_export_uploads fk_rails_0ad7734ce2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_export_uploads
    ADD CONSTRAINT fk_rails_0ad7734ce2 FOREIGN KEY (analytics_export_id) REFERENCES public.analytics_exports(id);


--
-- TOC entry 7348 (class 2606 OID 97425)
-- Name: calls_dashboard_customize_column_orders fk_rails_0ae859e0ac; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.calls_dashboard_customize_column_orders
    ADD CONSTRAINT fk_rails_0ae859e0ac FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7400 (class 2606 OID 97430)
-- Name: lead_integration_macros fk_rails_0b9f96d1be; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_macros
    ADD CONSTRAINT fk_rails_0b9f96d1be FOREIGN KEY (lead_integration_id) REFERENCES public.lead_integrations(id);


--
-- TOC entry 7438 (class 2606 OID 97435)
-- Name: questions fk_rails_102c50cef3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT fk_rails_102c50cef3 FOREIGN KEY (quote_funnel_id) REFERENCES public.quote_funnels(id);


--
-- TOC entry 7360 (class 2606 OID 97440)
-- Name: campaign_filters fk_rails_10dcb9aba8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filters
    ADD CONSTRAINT fk_rails_10dcb9aba8 FOREIGN KEY (sf_filter_id) REFERENCES public.sf_filters(id);


--
-- TOC entry 7367 (class 2606 OID 97445)
-- Name: campaign_pixel_columns fk_rails_10e254127c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_pixel_columns
    ADD CONSTRAINT fk_rails_10e254127c FOREIGN KEY (click_conversion_pixel_id) REFERENCES public.click_conversion_pixels(id);


--
-- TOC entry 7421 (class 2606 OID 97450)
-- Name: page_groups fk_rails_1130de5499; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_groups
    ADD CONSTRAINT fk_rails_1130de5499 FOREIGN KEY (quote_funnel_id) REFERENCES public.quote_funnels(id);


--
-- TOC entry 7309 (class 2606 OID 97455)
-- Name: admin_notification_template_types fk_rails_11979418a6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notification_template_types
    ADD CONSTRAINT fk_rails_11979418a6 FOREIGN KEY (admin_notification_template_id) REFERENCES public.admin_notification_templates(id);


--
-- TOC entry 7293 (class 2606 OID 97460)
-- Name: ad_group_ads fk_rails_127f8544e3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_ads
    ADD CONSTRAINT fk_rails_127f8544e3 FOREIGN KEY (ad_group_id) REFERENCES public.ad_groups(id);


--
-- TOC entry 7451 (class 2606 OID 97465)
-- Name: recently_visited_client_users fk_rails_1483b1c88b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recently_visited_client_users
    ADD CONSTRAINT fk_rails_1483b1c88b FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7495 (class 2606 OID 97470)
-- Name: whitelabeled_brands_user_login_mappings fk_rails_156fca73be; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelabeled_brands_user_login_mappings
    ADD CONSTRAINT fk_rails_156fca73be FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7324 (class 2606 OID 97475)
-- Name: analytic_pixel_columns fk_rails_16beeadbd6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytic_pixel_columns
    ADD CONSTRAINT fk_rails_16beeadbd6 FOREIGN KEY (click_conversion_pixel_id) REFERENCES public.click_conversion_pixels(id);


--
-- TOC entry 7319 (class 2606 OID 97480)
-- Name: admin_users fk_rails_17288c86b7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT fk_rails_17288c86b7 FOREIGN KEY (team_lead_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7447 (class 2606 OID 97485)
-- Name: receipts fk_rails_1b0ae87803; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipts
    ADD CONSTRAINT fk_rails_1b0ae87803 FOREIGN KEY (receipt_type_id) REFERENCES public.receipt_types(id);


--
-- TOC entry 7377 (class 2606 OID 97490)
-- Name: campaigns fk_rails_1bfd648c33; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT fk_rails_1bfd648c33 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7345 (class 2606 OID 97495)
-- Name: call_transcription_settings fk_rails_1c0501ea27; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_settings
    ADD CONSTRAINT fk_rails_1c0501ea27 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7380 (class 2606 OID 97500)
-- Name: campaigns_customize_columns_orders fk_rails_1cf14403bb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns_customize_columns_orders
    ADD CONSTRAINT fk_rails_1cf14403bb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7434 (class 2606 OID 97505)
-- Name: qf_quote_call_transcriptions fk_rails_1e6a574152; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_transcriptions
    ADD CONSTRAINT fk_rails_1e6a574152 FOREIGN KEY (qf_quote_call_id) REFERENCES public.qf_quote_calls(id);


--
-- TOC entry 7424 (class 2606 OID 97510)
-- Name: permissions fk_rails_2078943d09; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT fk_rails_2078943d09 FOREIGN KEY (feature_id) REFERENCES public.features(id);


--
-- TOC entry 7428 (class 2606 OID 97515)
-- Name: postback_url_req_logs fk_rails_23db00cb4b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postback_url_req_logs
    ADD CONSTRAINT fk_rails_23db00cb4b FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7323 (class 2606 OID 97520)
-- Name: agent_profiles fk_rails_2498a5554a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_profiles
    ADD CONSTRAINT fk_rails_2498a5554a FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7466 (class 2606 OID 97525)
-- Name: source_setting_notes fk_rails_2574acc58c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_setting_notes
    ADD CONSTRAINT fk_rails_2574acc58c FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7448 (class 2606 OID 97530)
-- Name: receipts fk_rails_2643c7e38c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipts
    ADD CONSTRAINT fk_rails_2643c7e38c FOREIGN KEY (receipt_transaction_type_id) REFERENCES public.receipt_transaction_types(id);


--
-- TOC entry 7430 (class 2606 OID 97535)
-- Name: prefill_queries fk_rails_28502d960c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prefill_queries
    ADD CONSTRAINT fk_rails_28502d960c FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- TOC entry 7462 (class 2606 OID 97540)
-- Name: sf_lead_integration_macro_lead_types fk_rails_2bbe050b17; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macro_lead_types
    ADD CONSTRAINT fk_rails_2bbe050b17 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7443 (class 2606 OID 97545)
-- Name: quote_call_summaries fk_rails_2c8111f8a7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_summaries
    ADD CONSTRAINT fk_rails_2c8111f8a7 FOREIGN KEY (quote_call_id) REFERENCES public.quote_calls(id);


--
-- TOC entry 7365 (class 2606 OID 97550)
-- Name: campaign_notes fk_rails_2dae476ca5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_notes
    ADD CONSTRAINT fk_rails_2dae476ca5 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7310 (class 2606 OID 97555)
-- Name: admin_permissions fk_rails_2e02b39c4d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT fk_rails_2e02b39c4d FOREIGN KEY (admin_feature_id) REFERENCES public.admin_features(id);


--
-- TOC entry 7456 (class 2606 OID 97560)
-- Name: scheduled_report_uploads fk_rails_2e7f7d95f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_uploads
    ADD CONSTRAINT fk_rails_2e7f7d95f1 FOREIGN KEY (scheduled_report_id) REFERENCES public.scheduled_reports(id);


--
-- TOC entry 7292 (class 2606 OID 97565)
-- Name: ad_contents fk_rails_2f3f0dd6f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_contents
    ADD CONSTRAINT fk_rails_2f3f0dd6f1 FOREIGN KEY (ad_id) REFERENCES public.ads(id);


--
-- TOC entry 7352 (class 2606 OID 97570)
-- Name: campaign_bid_modifiers fk_rails_2fb3eb1992; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_bid_modifiers
    ADD CONSTRAINT fk_rails_2fb3eb1992 FOREIGN KEY (sf_filter_id) REFERENCES public.sf_filters(id);


--
-- TOC entry 7291 (class 2606 OID 97575)
-- Name: account_balances fk_rails_30b52bf707; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_balances
    ADD CONSTRAINT fk_rails_30b52bf707 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7449 (class 2606 OID 97580)
-- Name: receipts fk_rails_333a62ca91; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipts
    ADD CONSTRAINT fk_rails_333a62ca91 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7483 (class 2606 OID 97585)
-- Name: user_column_preference_call_source_settings fk_rails_350f6a3575; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_call_source_settings
    ADD CONSTRAINT fk_rails_350f6a3575 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7333 (class 2606 OID 97590)
-- Name: automation_test_suite_results fk_rails_38355d7f8a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_test_suite_results
    ADD CONSTRAINT fk_rails_38355d7f8a FOREIGN KEY (automation_test_execution_result_id) REFERENCES public.automation_test_execution_results(id);


--
-- TOC entry 7390 (class 2606 OID 97595)
-- Name: invoices fk_rails_394fae067d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_394fae067d FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- TOC entry 7489 (class 2606 OID 97600)
-- Name: user_column_preference_prospects fk_rails_39529b190d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_prospects
    ADD CONSTRAINT fk_rails_39529b190d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7303 (class 2606 OID 97605)
-- Name: ad_groups fk_rails_3a99cbf7a5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_groups
    ADD CONSTRAINT fk_rails_3a99cbf7a5 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7302 (class 2606 OID 97610)
-- Name: ad_group_pixel_columns fk_rails_3ad5853476; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_pixel_columns
    ADD CONSTRAINT fk_rails_3ad5853476 FOREIGN KEY (click_conversion_pixel_id) REFERENCES public.click_conversion_pixels(id);


--
-- TOC entry 7338 (class 2606 OID 97615)
-- Name: billing_settings fk_rails_3bb5be6a74; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_settings
    ADD CONSTRAINT fk_rails_3bb5be6a74 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7460 (class 2606 OID 97620)
-- Name: sf_filters fk_rails_3bc473593a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_filters
    ADD CONSTRAINT fk_rails_3bc473593a FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7473 (class 2606 OID 97625)
-- Name: user_col_pref_admin_dashboards fk_rails_3cfa7389b3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_admin_dashboards
    ADD CONSTRAINT fk_rails_3cfa7389b3 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7463 (class 2606 OID 97630)
-- Name: sf_lead_integration_macro_lead_types fk_rails_3d4ca6d89a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_lead_integration_macro_lead_types
    ADD CONSTRAINT fk_rails_3d4ca6d89a FOREIGN KEY (sf_lead_integration_macro_id) REFERENCES public.sf_lead_integration_macros(id);


--
-- TOC entry 7299 (class 2606 OID 97635)
-- Name: ad_group_locations fk_rails_40e5bf67cc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_locations
    ADD CONSTRAINT fk_rails_40e5bf67cc FOREIGN KEY (ad_group_id) REFERENCES public.ad_groups(id);


--
-- TOC entry 7305 (class 2606 OID 97640)
-- Name: admin_assignments fk_rails_422bec3303; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_assignments
    ADD CONSTRAINT fk_rails_422bec3303 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7410 (class 2606 OID 97645)
-- Name: lead_violations fk_rails_42ccbaf512; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_violations
    ADD CONSTRAINT fk_rails_42ccbaf512 FOREIGN KEY (lead_applicant_id) REFERENCES public.lead_applicants(id);


--
-- TOC entry 7341 (class 2606 OID 97650)
-- Name: call_campaign_settings fk_rails_44b3d8683b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_campaign_settings
    ADD CONSTRAINT fk_rails_44b3d8683b FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7388 (class 2606 OID 97655)
-- Name: filter_package_filters fk_rails_46624d9b08; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filter_package_filters
    ADD CONSTRAINT fk_rails_46624d9b08 FOREIGN KEY (filter_package_id) REFERENCES public.filter_packages(id);


--
-- TOC entry 7413 (class 2606 OID 97660)
-- Name: leads fk_rails_47f0086a23; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT fk_rails_47f0086a23 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7344 (class 2606 OID 97665)
-- Name: call_transcription_rules fk_rails_48c445d8df; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_rules
    ADD CONSTRAINT fk_rails_48c445d8df FOREIGN KEY (call_transcription_topic_id) REFERENCES public.call_transcription_topics(id);


--
-- TOC entry 7439 (class 2606 OID 97670)
-- Name: questions fk_rails_493b2e8c46; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT fk_rails_493b2e8c46 FOREIGN KEY (question_group_id) REFERENCES public.question_groups(id);


--
-- TOC entry 7353 (class 2606 OID 97675)
-- Name: campaign_bid_modifiers fk_rails_4b0545807f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_bid_modifiers
    ADD CONSTRAINT fk_rails_4b0545807f FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7307 (class 2606 OID 97680)
-- Name: admin_clients_customize_columns_orders fk_rails_4ee353a317; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_clients_customize_columns_orders
    ADD CONSTRAINT fk_rails_4ee353a317 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7294 (class 2606 OID 97685)
-- Name: ad_group_ads fk_rails_4f5374e8e1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_ads
    ADD CONSTRAINT fk_rails_4f5374e8e1 FOREIGN KEY (ad_id) REFERENCES public.ads(id);


--
-- TOC entry 7490 (class 2606 OID 97690)
-- Name: user_column_preference_source_settings fk_rails_51f1639074; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_source_settings
    ADD CONSTRAINT fk_rails_51f1639074 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7326 (class 2606 OID 97695)
-- Name: analytics_exports fk_rails_53e32c9700; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_exports
    ADD CONSTRAINT fk_rails_53e32c9700 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7295 (class 2606 OID 97700)
-- Name: ad_group_filter_groups fk_rails_553a3ad37d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filter_groups
    ADD CONSTRAINT fk_rails_553a3ad37d FOREIGN KEY (ad_group_id) REFERENCES public.ad_groups(id);


--
-- TOC entry 7314 (class 2606 OID 97705)
-- Name: admin_user_column_preferences fk_rails_57ea942996; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_column_preferences
    ADD CONSTRAINT fk_rails_57ea942996 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7296 (class 2606 OID 97710)
-- Name: ad_group_filters fk_rails_59a1339a1d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filters
    ADD CONSTRAINT fk_rails_59a1339a1d FOREIGN KEY (ad_group_id) REFERENCES public.ad_groups(id);


--
-- TOC entry 7407 (class 2606 OID 97715)
-- Name: lead_refunds fk_rails_59ae5888b8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_refunds
    ADD CONSTRAINT fk_rails_59ae5888b8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7350 (class 2606 OID 97720)
-- Name: campaign_ads fk_rails_5a45166f9f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_ads
    ADD CONSTRAINT fk_rails_5a45166f9f FOREIGN KEY (ad_id) REFERENCES public.ads(id);


--
-- TOC entry 7414 (class 2606 OID 97725)
-- Name: leads fk_rails_5a793df820; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT fk_rails_5a793df820 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7467 (class 2606 OID 97730)
-- Name: source_setting_notes fk_rails_5cc67a873c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_setting_notes
    ADD CONSTRAINT fk_rails_5cc67a873c FOREIGN KEY (campaign_source_setting_id) REFERENCES public.campaign_source_settings(id);


--
-- TOC entry 7461 (class 2606 OID 97735)
-- Name: sf_filters fk_rails_5d522c17c0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_filters
    ADD CONSTRAINT fk_rails_5d522c17c0 FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- TOC entry 7497 (class 2606 OID 97740)
-- Name: whitelisting_brand_admin_assignments fk_rails_5e8b4ed995; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelisting_brand_admin_assignments
    ADD CONSTRAINT fk_rails_5e8b4ed995 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7426 (class 2606 OID 97745)
-- Name: popup_lead_type_messages fk_rails_5f2bc57ebb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.popup_lead_type_messages
    ADD CONSTRAINT fk_rails_5f2bc57ebb FOREIGN KEY (agent_profile_id) REFERENCES public.agent_profiles(id);


--
-- TOC entry 7346 (class 2606 OID 97750)
-- Name: call_transcription_topics fk_rails_5f67bfb80f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_transcription_topics
    ADD CONSTRAINT fk_rails_5f67bfb80f FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7418 (class 2606 OID 97755)
-- Name: leads_dashboard_customize_column_orders fk_rails_6124ea4dec; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads_dashboard_customize_column_orders
    ADD CONSTRAINT fk_rails_6124ea4dec FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7381 (class 2606 OID 97760)
-- Name: click_ad_group_settings fk_rails_63e9721af0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.click_ad_group_settings
    ADD CONSTRAINT fk_rails_63e9721af0 FOREIGN KEY (ad_group_id) REFERENCES public.ad_groups(id);


--
-- TOC entry 7481 (class 2606 OID 97765)
-- Name: user_column_preference_ad_groups fk_rails_64824541a8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_ad_groups
    ADD CONSTRAINT fk_rails_64824541a8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7334 (class 2606 OID 97770)
-- Name: bill_com_invoices fk_rails_6534341ef8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_invoices
    ADD CONSTRAINT fk_rails_6534341ef8 FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- TOC entry 7404 (class 2606 OID 97775)
-- Name: lead_integration_req_payloads fk_rails_676d4e58fa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_payloads
    ADD CONSTRAINT fk_rails_676d4e58fa FOREIGN KEY (lead_integration_id) REFERENCES public.lead_integrations(id);


--
-- TOC entry 7485 (class 2606 OID 97780)
-- Name: user_column_preference_campaigns fk_rails_693eae5910; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_campaigns
    ADD CONSTRAINT fk_rails_693eae5910 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7372 (class 2606 OID 97785)
-- Name: campaign_source_settings fk_rails_6b576a94d9; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_source_settings
    ADD CONSTRAINT fk_rails_6b576a94d9 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7452 (class 2606 OID 97790)
-- Name: recently_visited_client_users fk_rails_7037be7ae3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recently_visited_client_users
    ADD CONSTRAINT fk_rails_7037be7ae3 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7465 (class 2606 OID 97795)
-- Name: source_pixel_columns fk_rails_7073817481; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_pixel_columns
    ADD CONSTRAINT fk_rails_7073817481 FOREIGN KEY (click_conversion_pixel_id) REFERENCES public.click_conversion_pixels(id);


--
-- TOC entry 7482 (class 2606 OID 97800)
-- Name: user_column_preference_call_profiles fk_rails_711d5995e8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_call_profiles
    ADD CONSTRAINT fk_rails_711d5995e8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7402 (class 2606 OID 97805)
-- Name: lead_integration_req_headers fk_rails_7136096a9d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_headers
    ADD CONSTRAINT fk_rails_7136096a9d FOREIGN KEY (lead_integration_id) REFERENCES public.lead_integrations(id);


--
-- TOC entry 7411 (class 2606 OID 97810)
-- Name: lead_violations fk_rails_78119218a6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_violations
    ADD CONSTRAINT fk_rails_78119218a6 FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- TOC entry 7480 (class 2606 OID 97815)
-- Name: user_col_pref_syndi_clicks_dashboards fk_rails_7828ce7105; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_syndi_clicks_dashboards
    ADD CONSTRAINT fk_rails_7828ce7105 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7332 (class 2606 OID 97820)
-- Name: assignments fk_rails_7a0906be01; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_7a0906be01 FOREIGN KEY (membership_id) REFERENCES public.memberships(id);


--
-- TOC entry 7412 (class 2606 OID 97825)
-- Name: lead_violations fk_rails_7b36a3e4f3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_violations
    ADD CONSTRAINT fk_rails_7b36a3e4f3 FOREIGN KEY (violation_type_id) REFERENCES public.violation_types(id);


--
-- TOC entry 7382 (class 2606 OID 97830)
-- Name: clicks_dashboard_customize_column_orders fk_rails_7ba1ca2f58; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clicks_dashboard_customize_column_orders
    ADD CONSTRAINT fk_rails_7ba1ca2f58 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7422 (class 2606 OID 97835)
-- Name: pages fk_rails_7be29645f6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT fk_rails_7be29645f6 FOREIGN KEY (quote_funnel_id) REFERENCES public.quote_funnels(id);


--
-- TOC entry 7453 (class 2606 OID 97840)
-- Name: roles fk_rails_7c71253d78; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_7c71253d78 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7445 (class 2606 OID 97845)
-- Name: quote_funnels fk_rails_7e25309f2c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_funnels
    ADD CONSTRAINT fk_rails_7e25309f2c FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7464 (class 2606 OID 97850)
-- Name: sf_smart_views fk_rails_7e46ded8b1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sf_smart_views
    ADD CONSTRAINT fk_rails_7e46ded8b1 FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- TOC entry 7468 (class 2606 OID 97855)
-- Name: syndi_click_settings fk_rails_7e6e88816f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.syndi_click_settings
    ADD CONSTRAINT fk_rails_7e6e88816f FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7385 (class 2606 OID 97860)
-- Name: email_export_logs fk_rails_8060007067; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_export_logs
    ADD CONSTRAINT fk_rails_8060007067 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7357 (class 2606 OID 97865)
-- Name: campaign_filter_groups fk_rails_816affccc2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filter_groups
    ADD CONSTRAINT fk_rails_816affccc2 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7389 (class 2606 OID 97870)
-- Name: filter_package_filters fk_rails_81df051e9b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.filter_package_filters
    ADD CONSTRAINT fk_rails_81df051e9b FOREIGN KEY (sf_filter_id) REFERENCES public.sf_filters(id);


--
-- TOC entry 7488 (class 2606 OID 97875)
-- Name: user_column_preference_leads fk_rails_833324fbe6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_leads
    ADD CONSTRAINT fk_rails_833324fbe6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7493 (class 2606 OID 97880)
-- Name: user_smart_views fk_rails_84e52ae10b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_smart_views
    ADD CONSTRAINT fk_rails_84e52ae10b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7342 (class 2606 OID 97885)
-- Name: call_campaign_settings fk_rails_861430e204; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_campaign_settings
    ADD CONSTRAINT fk_rails_861430e204 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7373 (class 2606 OID 97890)
-- Name: campaign_source_settings fk_rails_865ae35b32; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_source_settings
    ADD CONSTRAINT fk_rails_865ae35b32 FOREIGN KEY (source_type_id) REFERENCES public.source_types(id);


--
-- TOC entry 7475 (class 2606 OID 97895)
-- Name: user_col_pref_calls_dashboard_campaigns fk_rails_89dd4d4dcc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_calls_dashboard_campaigns
    ADD CONSTRAINT fk_rails_89dd4d4dcc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7300 (class 2606 OID 97900)
-- Name: ad_group_notes fk_rails_8ae7273818; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_notes
    ADD CONSTRAINT fk_rails_8ae7273818 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7297 (class 2606 OID 97905)
-- Name: ad_group_filters fk_rails_8b1c033461; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filters
    ADD CONSTRAINT fk_rails_8b1c033461 FOREIGN KEY (sf_filter_id) REFERENCES public.sf_filters(id);


--
-- TOC entry 7378 (class 2606 OID 97910)
-- Name: campaigns fk_rails_8c2e54524d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT fk_rails_8c2e54524d FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- TOC entry 7311 (class 2606 OID 97915)
-- Name: admin_permissions fk_rails_8cff78c3b5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT fk_rails_8cff78c3b5 FOREIGN KEY (admin_role_id) REFERENCES public.admin_roles(id);


--
-- TOC entry 7395 (class 2606 OID 97920)
-- Name: lead_campaign_settings fk_rails_8ec5b239ca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_campaign_settings
    ADD CONSTRAINT fk_rails_8ec5b239ca FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7366 (class 2606 OID 97925)
-- Name: campaign_notes fk_rails_8f3fe25ef7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_notes
    ADD CONSTRAINT fk_rails_8f3fe25ef7 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7298 (class 2606 OID 97930)
-- Name: ad_group_filters fk_rails_8f6b042d5c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_filters
    ADD CONSTRAINT fk_rails_8f6b042d5c FOREIGN KEY (ad_group_filter_group_id) REFERENCES public.ad_group_filter_groups(id);


--
-- TOC entry 7425 (class 2606 OID 97935)
-- Name: permissions fk_rails_93c739e1a2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT fk_rails_93c739e1a2 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- TOC entry 7432 (class 2606 OID 97940)
-- Name: qf_quote_call_qas fk_rails_9505463c29; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_qas
    ADD CONSTRAINT fk_rails_9505463c29 FOREIGN KEY (qf_quote_call_id) REFERENCES public.qf_quote_calls(id);


--
-- TOC entry 7408 (class 2606 OID 97945)
-- Name: lead_vehicles fk_rails_97079467c7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_vehicles
    ADD CONSTRAINT fk_rails_97079467c7 FOREIGN KEY (lead_applicant_id) REFERENCES public.lead_applicants(id);


--
-- TOC entry 7336 (class 2606 OID 97950)
-- Name: billing_setting_invoice_changes fk_rails_987c4eac49; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_setting_invoice_changes
    ADD CONSTRAINT fk_rails_987c4eac49 FOREIGN KEY (billing_setting_id) REFERENCES public.billing_settings(id);


--
-- TOC entry 7470 (class 2606 OID 97955)
-- Name: template_assignments fk_rails_991fa7af2a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_assignments
    ADD CONSTRAINT fk_rails_991fa7af2a FOREIGN KEY (admin_notification_template_id) REFERENCES public.admin_notification_templates(id);


--
-- TOC entry 7419 (class 2606 OID 97960)
-- Name: memberships fk_rails_99326fb65d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_99326fb65d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7393 (class 2606 OID 97965)
-- Name: lead_applicants fk_rails_9d49ab7fc3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_applicants
    ADD CONSTRAINT fk_rails_9d49ab7fc3 FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- TOC entry 7403 (class 2606 OID 97970)
-- Name: lead_integration_req_logs fk_rails_9ebf591396; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_logs
    ADD CONSTRAINT fk_rails_9ebf591396 FOREIGN KEY (lead_integration_id) REFERENCES public.lead_integrations(id);


--
-- TOC entry 7440 (class 2606 OID 97975)
-- Name: questions fk_rails_a0bb221df6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT fk_rails_a0bb221df6 FOREIGN KEY (page_id) REFERENCES public.pages(id);


--
-- TOC entry 7441 (class 2606 OID 97980)
-- Name: questions fk_rails_a155c4f37e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT fk_rails_a155c4f37e FOREIGN KEY (page_group_id) REFERENCES public.page_groups(id);


--
-- TOC entry 7436 (class 2606 OID 97985)
-- Name: question_groups fk_rails_a4605b4114; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.question_groups
    ADD CONSTRAINT fk_rails_a4605b4114 FOREIGN KEY (page_group_id) REFERENCES public.page_groups(id);


--
-- TOC entry 7316 (class 2606 OID 97990)
-- Name: admin_user_notifications_preferences fk_rails_a948b81842; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_notifications_preferences
    ADD CONSTRAINT fk_rails_a948b81842 FOREIGN KEY (admin_notification_type_id) REFERENCES public.admin_notification_types(id);


--
-- TOC entry 7494 (class 2606 OID 97995)
-- Name: versions fk_rails_a9c0d83557; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT fk_rails_a9c0d83557 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7415 (class 2606 OID 98000)
-- Name: leads fk_rails_a9ef1e2114; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT fk_rails_a9ef1e2114 FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- TOC entry 7416 (class 2606 OID 98005)
-- Name: leads fk_rails_aa52b00e14; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT fk_rails_aa52b00e14 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7479 (class 2606 OID 98010)
-- Name: user_col_pref_leads_dashboards fk_rails_af7726cbe6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_leads_dashboards
    ADD CONSTRAINT fk_rails_af7726cbe6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7312 (class 2606 OID 98015)
-- Name: admin_slack_notification_logs fk_rails_af8636e5dc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_slack_notification_logs
    ADD CONSTRAINT fk_rails_af8636e5dc FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7474 (class 2606 OID 98020)
-- Name: user_col_pref_analytics fk_rails_af8b1a93f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_analytics
    ADD CONSTRAINT fk_rails_af8b1a93f1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7391 (class 2606 OID 98025)
-- Name: invoices fk_rails_afb4b1e584; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_afb4b1e584 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7363 (class 2606 OID 98030)
-- Name: campaign_lead_integrations fk_rails_afcfc11719; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_lead_integrations
    ADD CONSTRAINT fk_rails_afcfc11719 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7321 (class 2606 OID 98035)
-- Name: ads fk_rails_afebf6632c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT fk_rails_afebf6632c FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- TOC entry 7433 (class 2606 OID 98040)
-- Name: qf_quote_call_summaries fk_rails_b0cafb1050; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qf_quote_call_summaries
    ADD CONSTRAINT fk_rails_b0cafb1050 FOREIGN KEY (qf_quote_call_id) REFERENCES public.qf_quote_calls(id);


--
-- TOC entry 7399 (class 2606 OID 98045)
-- Name: lead_integration_macro_mappings fk_rails_b101163604; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_macro_mappings
    ADD CONSTRAINT fk_rails_b101163604 FOREIGN KEY (lead_integration_macro_id) REFERENCES public.lead_integration_macros(id);


--
-- TOC entry 7405 (class 2606 OID 98050)
-- Name: lead_integration_req_payloads fk_rails_b1624ea6f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_req_payloads
    ADD CONSTRAINT fk_rails_b1624ea6f1 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7450 (class 2606 OID 98055)
-- Name: receipts fk_rails_b2d4d3fa14; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receipts
    ADD CONSTRAINT fk_rails_b2d4d3fa14 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7370 (class 2606 OID 98060)
-- Name: campaign_schedules fk_rails_b2efcebaae; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_schedules
    ADD CONSTRAINT fk_rails_b2efcebaae FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7401 (class 2606 OID 98065)
-- Name: lead_integration_macros fk_rails_b442d4822b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_integration_macros
    ADD CONSTRAINT fk_rails_b442d4822b FOREIGN KEY (sf_lead_integration_macro_id) REFERENCES public.sf_lead_integration_macros(id);


--
-- TOC entry 7368 (class 2606 OID 98070)
-- Name: campaign_quote_funnels fk_rails_b4a0b2c6c0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_quote_funnels
    ADD CONSTRAINT fk_rails_b4a0b2c6c0 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7406 (class 2606 OID 98075)
-- Name: lead_prices fk_rails_b5ec94218a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_prices
    ADD CONSTRAINT fk_rails_b5ec94218a FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7486 (class 2606 OID 98080)
-- Name: user_column_preference_lead_profiles fk_rails_b65cff2ab0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_lead_profiles
    ADD CONSTRAINT fk_rails_b65cff2ab0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7315 (class 2606 OID 98085)
-- Name: admin_user_customize_column_orders fk_rails_b6d98ba95f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_customize_column_orders
    ADD CONSTRAINT fk_rails_b6d98ba95f FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7337 (class 2606 OID 98090)
-- Name: billing_setting_invoice_changes fk_rails_b7a0b35b7d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_setting_invoice_changes
    ADD CONSTRAINT fk_rails_b7a0b35b7d FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7472 (class 2606 OID 98095)
-- Name: user_activity_customize_columns_orders fk_rails_ba7bcff82f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_activity_customize_columns_orders
    ADD CONSTRAINT fk_rails_ba7bcff82f FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7327 (class 2606 OID 98100)
-- Name: analytics_exports fk_rails_bd2b375e31; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_exports
    ADD CONSTRAINT fk_rails_bd2b375e31 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7431 (class 2606 OID 98105)
-- Name: prospects_customize_columns_orders fk_rails_bd44fb091d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prospects_customize_columns_orders
    ADD CONSTRAINT fk_rails_bd44fb091d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7306 (class 2606 OID 98110)
-- Name: admin_assignments fk_rails_be6c90ef3e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_assignments
    ADD CONSTRAINT fk_rails_be6c90ef3e FOREIGN KEY (admin_role_id) REFERENCES public.admin_roles(id);


--
-- TOC entry 7487 (class 2606 OID 98115)
-- Name: user_column_preference_lead_source_settings fk_rails_bf91bd44eb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_lead_source_settings
    ADD CONSTRAINT fk_rails_bf91bd44eb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7361 (class 2606 OID 98120)
-- Name: campaign_filters fk_rails_c0b6a65124; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filters
    ADD CONSTRAINT fk_rails_c0b6a65124 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7328 (class 2606 OID 98125)
-- Name: analytics_exports fk_rails_c117ffad01; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_exports
    ADD CONSTRAINT fk_rails_c117ffad01 FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- TOC entry 7442 (class 2606 OID 98130)
-- Name: quote_call_qas fk_rails_c2c895bbfe; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_qas
    ADD CONSTRAINT fk_rails_c2c895bbfe FOREIGN KEY (quote_call_id) REFERENCES public.quote_calls(id);


--
-- TOC entry 7417 (class 2606 OID 98135)
-- Name: leads_customize_columns_orders fk_rails_c562d409af; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leads_customize_columns_orders
    ADD CONSTRAINT fk_rails_c562d409af FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7394 (class 2606 OID 98140)
-- Name: lead_business_entities fk_rails_c69162786a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_business_entities
    ADD CONSTRAINT fk_rails_c69162786a FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- TOC entry 7471 (class 2606 OID 98145)
-- Name: template_assignments fk_rails_c6b0b14357; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_assignments
    ADD CONSTRAINT fk_rails_c6b0b14357 FOREIGN KEY (admin_role_id) REFERENCES public.admin_roles(id);


--
-- TOC entry 7454 (class 2606 OID 98150)
-- Name: sample_leads fk_rails_c7ce8ecf24; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sample_leads
    ADD CONSTRAINT fk_rails_c7ce8ecf24 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7379 (class 2606 OID 98155)
-- Name: campaigns fk_rails_c80a08c7b9; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT fk_rails_c80a08c7b9 FOREIGN KEY (brand_id) REFERENCES public.brands(id);


--
-- TOC entry 7364 (class 2606 OID 98160)
-- Name: campaign_lead_integrations fk_rails_c850e9e2ee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_lead_integrations
    ADD CONSTRAINT fk_rails_c850e9e2ee FOREIGN KEY (lead_integration_id) REFERENCES public.lead_integrations(id);


--
-- TOC entry 7386 (class 2606 OID 98165)
-- Name: email_export_logs fk_rails_cba44b8b28; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_export_logs
    ADD CONSTRAINT fk_rails_cba44b8b28 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7478 (class 2606 OID 98170)
-- Name: user_col_pref_conversion_logs fk_rails_cce85fec93; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_conversion_logs
    ADD CONSTRAINT fk_rails_cce85fec93 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7491 (class 2606 OID 98175)
-- Name: user_notifications fk_rails_cdbff2ee9e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT fk_rails_cdbff2ee9e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7335 (class 2606 OID 98180)
-- Name: bill_com_invoices fk_rails_ce5748955d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_com_invoices
    ADD CONSTRAINT fk_rails_ce5748955d FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7355 (class 2606 OID 98185)
-- Name: campaign_budgets fk_rails_cfd57698d1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_budgets
    ADD CONSTRAINT fk_rails_cfd57698d1 FOREIGN KEY (day_id) REFERENCES public.days(id);


--
-- TOC entry 7318 (class 2606 OID 98190)
-- Name: admin_user_smart_views fk_rails_d0354c9d01; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_smart_views
    ADD CONSTRAINT fk_rails_d0354c9d01 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7476 (class 2606 OID 98195)
-- Name: user_col_pref_calls_dashboard_states fk_rails_d11f3621cb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_calls_dashboard_states
    ADD CONSTRAINT fk_rails_d11f3621cb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7477 (class 2606 OID 98200)
-- Name: user_col_pref_clicks_dashboards fk_rails_d21084933e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_col_pref_clicks_dashboards
    ADD CONSTRAINT fk_rails_d21084933e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7469 (class 2606 OID 98205)
-- Name: syndi_click_settings fk_rails_d323f204e2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.syndi_click_settings
    ADD CONSTRAINT fk_rails_d323f204e2 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7457 (class 2606 OID 98210)
-- Name: scheduled_reports fk_rails_d48c1dbae3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_reports
    ADD CONSTRAINT fk_rails_d48c1dbae3 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7444 (class 2606 OID 98215)
-- Name: quote_call_transcriptions fk_rails_d4e1c50a2c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_call_transcriptions
    ADD CONSTRAINT fk_rails_d4e1c50a2c FOREIGN KEY (quote_call_id) REFERENCES public.quote_calls(id);


--
-- TOC entry 7304 (class 2606 OID 98220)
-- Name: ad_groups fk_rails_d522d3207e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_groups
    ADD CONSTRAINT fk_rails_d522d3207e FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7484 (class 2606 OID 98225)
-- Name: user_column_preference_calls fk_rails_d669ab6114; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_column_preference_calls
    ADD CONSTRAINT fk_rails_d669ab6114 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7371 (class 2606 OID 98230)
-- Name: campaign_schedules fk_rails_d6e02a741d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_schedules
    ADD CONSTRAINT fk_rails_d6e02a741d FOREIGN KEY (day_id) REFERENCES public.days(id);


--
-- TOC entry 7347 (class 2606 OID 98235)
-- Name: calls_customize_columns_orders fk_rails_d8e4ee1e66; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.calls_customize_columns_orders
    ADD CONSTRAINT fk_rails_d8e4ee1e66 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7429 (class 2606 OID 98240)
-- Name: postback_url_req_logs fk_rails_d955b53f13; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postback_url_req_logs
    ADD CONSTRAINT fk_rails_d955b53f13 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7317 (class 2606 OID 98245)
-- Name: admin_user_notifications_preferences fk_rails_d97b3a7397; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_notifications_preferences
    ADD CONSTRAINT fk_rails_d97b3a7397 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7374 (class 2606 OID 98250)
-- Name: campaign_spends fk_rails_db4c5d9db7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_spends
    ADD CONSTRAINT fk_rails_db4c5d9db7 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7383 (class 2606 OID 98255)
-- Name: conversions_logs_pixel_cols fk_rails_dbc2c93b24; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversions_logs_pixel_cols
    ADD CONSTRAINT fk_rails_dbc2c93b24 FOREIGN KEY (click_conversion_pixel_id) REFERENCES public.click_conversion_pixels(id);


--
-- TOC entry 7458 (class 2606 OID 98260)
-- Name: scheduled_reports fk_rails_e05e204575; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_reports
    ADD CONSTRAINT fk_rails_e05e204575 FOREIGN KEY (user_smart_view_id) REFERENCES public.user_smart_views(id);


--
-- TOC entry 7359 (class 2606 OID 98265)
-- Name: campaign_filter_packages fk_rails_e069ce75d3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filter_packages
    ADD CONSTRAINT fk_rails_e069ce75d3 FOREIGN KEY (filter_package_id) REFERENCES public.filter_packages(id);


--
-- TOC entry 7427 (class 2606 OID 98270)
-- Name: popup_lead_type_messages fk_rails_e10108dee0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.popup_lead_type_messages
    ADD CONSTRAINT fk_rails_e10108dee0 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7339 (class 2606 OID 98275)
-- Name: brands fk_rails_e23d885924; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT fk_rails_e23d885924 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7375 (class 2606 OID 98280)
-- Name: campaign_spends fk_rails_e48bf0baa1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_spends
    ADD CONSTRAINT fk_rails_e48bf0baa1 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7320 (class 2606 OID 98285)
-- Name: admin_users fk_rails_e4ce59bd8f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT fk_rails_e4ce59bd8f FOREIGN KEY (manager_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7330 (class 2606 OID 98290)
-- Name: api_timing_api_profiling_tags fk_rails_e55f3f12cf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_timing_api_profiling_tags
    ADD CONSTRAINT fk_rails_e55f3f12cf FOREIGN KEY (api_timing_id) REFERENCES public.api_timings(id);


--
-- TOC entry 7498 (class 2606 OID 98295)
-- Name: whitelisting_brand_admin_assignments fk_rails_e5b3ac175e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelisting_brand_admin_assignments
    ADD CONSTRAINT fk_rails_e5b3ac175e FOREIGN KEY (white_listing_brand_id) REFERENCES public.white_listing_brands(id);


--
-- TOC entry 7362 (class 2606 OID 98300)
-- Name: campaign_filters fk_rails_e6b3f6a1a4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_filters
    ADD CONSTRAINT fk_rails_e6b3f6a1a4 FOREIGN KEY (campaign_filter_group_id) REFERENCES public.campaign_filter_groups(id);


--
-- TOC entry 7396 (class 2606 OID 98305)
-- Name: lead_campaign_settings fk_rails_e6bf351acc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_campaign_settings
    ADD CONSTRAINT fk_rails_e6bf351acc FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7409 (class 2606 OID 98310)
-- Name: lead_vehicles fk_rails_e7242b20e7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_vehicles
    ADD CONSTRAINT fk_rails_e7242b20e7 FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- TOC entry 7351 (class 2606 OID 98315)
-- Name: campaign_bid_modifier_groups fk_rails_e7c6603dfc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_bid_modifier_groups
    ADD CONSTRAINT fk_rails_e7c6603dfc FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- TOC entry 7459 (class 2606 OID 98320)
-- Name: scheduled_reports fk_rails_ea8572c25a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_reports
    ADD CONSTRAINT fk_rails_ea8572c25a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7356 (class 2606 OID 98325)
-- Name: campaign_dashboard_colunm_orders fk_rails_eacbf899bf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_dashboard_colunm_orders
    ADD CONSTRAINT fk_rails_eacbf899bf FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7343 (class 2606 OID 98330)
-- Name: call_prices fk_rails_ec58e37a97; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_prices
    ADD CONSTRAINT fk_rails_ec58e37a97 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7496 (class 2606 OID 98335)
-- Name: whitelabeled_brands_user_login_mappings fk_rails_ecb860b782; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.whitelabeled_brands_user_login_mappings
    ADD CONSTRAINT fk_rails_ecb860b782 FOREIGN KEY (white_listing_brand_id) REFERENCES public.white_listing_brands(id);


--
-- TOC entry 7420 (class 2606 OID 98340)
-- Name: memberships fk_rails_edbc202c67; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_edbc202c67 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7455 (class 2606 OID 98345)
-- Name: scheduled_report_logs fk_rails_ef5937f65f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_report_logs
    ADD CONSTRAINT fk_rails_ef5937f65f FOREIGN KEY (scheduled_report_id) REFERENCES public.scheduled_reports(id);


--
-- TOC entry 7369 (class 2606 OID 98350)
-- Name: campaign_quote_funnels fk_rails_efbc063ae1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_quote_funnels
    ADD CONSTRAINT fk_rails_efbc063ae1 FOREIGN KEY (quote_funnel_id) REFERENCES public.quote_funnels(id);


--
-- TOC entry 7301 (class 2606 OID 98355)
-- Name: ad_group_notes fk_rails_f05216cf85; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_group_notes
    ADD CONSTRAINT fk_rails_f05216cf85 FOREIGN KEY (ad_group_id) REFERENCES public.ad_groups(id);


--
-- TOC entry 7387 (class 2606 OID 98360)
-- Name: email_export_logs fk_rails_f2a583a03d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_export_logs
    ADD CONSTRAINT fk_rails_f2a583a03d FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7329 (class 2606 OID 98365)
-- Name: analytics_exports fk_rails_f435f72e34; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_exports
    ADD CONSTRAINT fk_rails_f435f72e34 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7392 (class 2606 OID 98370)
-- Name: invoices fk_rails_f558c6adad; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_f558c6adad FOREIGN KEY (payment_term_id) REFERENCES public.payment_terms(id);


--
-- TOC entry 7437 (class 2606 OID 98375)
-- Name: question_groups fk_rails_f5985afaba; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.question_groups
    ADD CONSTRAINT fk_rails_f5985afaba FOREIGN KEY (page_id) REFERENCES public.pages(id);


--
-- TOC entry 7313 (class 2606 OID 98380)
-- Name: admin_user_col_pref_user_activities fk_rails_f5ec4a05fa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_col_pref_user_activities
    ADD CONSTRAINT fk_rails_f5ec4a05fa FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- TOC entry 7322 (class 2606 OID 98385)
-- Name: ads fk_rails_fad155090c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT fk_rails_fad155090c FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- TOC entry 7340 (class 2606 OID 98390)
-- Name: call_ad_group_settings fk_rails_fb917844bc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_ad_group_settings
    ADD CONSTRAINT fk_rails_fb917844bc FOREIGN KEY (ad_group_id) REFERENCES public.ad_groups(id);


--
-- TOC entry 7384 (class 2606 OID 98395)
-- Name: customize_orders fk_rails_fcd39f0f3e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customize_orders
    ADD CONSTRAINT fk_rails_fcd39f0f3e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 7423 (class 2606 OID 98400)
-- Name: pages fk_rails_fcdc18abdc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT fk_rails_fcdc18abdc FOREIGN KEY (page_group_id) REFERENCES public.page_groups(id);


--
-- TOC entry 7446 (class 2606 OID 98405)
-- Name: quote_funnels_prices fk_rails_fd31d540a4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quote_funnels_prices
    ADD CONSTRAINT fk_rails_fd31d540a4 FOREIGN KEY (lead_type_id) REFERENCES public.lead_types(id);


--
-- TOC entry 7398 (class 2606 OID 98410)
-- Name: lead_homes fk_rails_fecc720bc8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead_homes
    ADD CONSTRAINT fk_rails_fecc720bc8 FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- TOC entry 7625 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2024-08-21 13:26:15 +06

--
-- PostgreSQL database dump complete
--

