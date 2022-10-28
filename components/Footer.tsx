import styles from './Footer.module.css';

export default function Footer() {
    return (
        <>
            <div className={styles.footer}>
                <p>r/UlryApp</p>
                <p>GitHub</p>
                <p>r/UlryAppBeta</p>
                <p>TestFlight</p>
                <p>Developer Website</p>
            </div>
        </>
    )
}